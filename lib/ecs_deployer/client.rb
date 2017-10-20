require 'yaml'
require 'oj'
require 'aws-sdk'
require 'base64'
require 'logger'

module EcsDeployer
  class Client
    LOG_SEPARATOR = '-' * 96
    ENCRYPT_PATTERN = /^\${(.+)}$/

    attr_reader :ecs
    attr_accessor :wait_timeout, :pauling_interval

    # @param [String] cluster
    # @param [Logger] logger
    # @return [EcsDeployer::Client]
    def initialize(cluster, logger = nil, aws_options = {})
      @cluster = cluster
      @logger = logger.nil? ? Logger.new(STDOUT) : logger
      @ecs = Aws::ECS::Client.new(aws_options)
      @kms = Aws::KMS::Client.new(aws_options)
      @wait_timeout = 900
      @pauling_interval = 20
    end

    # @param [String] mater_key
    # @param [String] value
    # @return [String]
    def encrypt(master_key, value)
      encode = @kms.encrypt(key_id: "alias/#{master_key}", plaintext: value)
      "${#{Base64.strict_encode64(encode.ciphertext_blob)}}"
    rescue => e
      raise KmsEncryptError, e.to_s
    end

    # @param [String] value
    # @return [String]
    def decrypt(value)
      match = value.match(ENCRYPT_PATTERN)
      raise KmsDecryptError, 'Encrypted string is invalid.' unless match

      begin
        @kms.decrypt(ciphertext_blob: Base64.strict_decode64(match[1])).plaintext
      rescue => e
        raise KmsDecryptError, e.to_s
      end
    end

    # @param [String] path
    # @param [Hash] replace_variables
    # @return [String]
    def register_task(path, replace_variables = {})
      raise IOError, "File does not exist. [#{path}]" unless File.exist?(path)

      register_task_hash(YAML.load(File.read(path)), replace_variables)
    end

    # @param [Hash] task_definition
    # @param [Hash] replace_variables
    # @return [Aws::ECS::Types::TaskDefinition]
    def register_task_hash(task_definition, replace_variables = {})
      task_definition = Oj.load(Oj.dump(task_definition), symbol_keys: true)

      replace_parameter_variables!(task_definition, replace_variables)
      decrypt_environment_variables!(task_definition)

      result = @ecs.register_task_definition(
        container_definitions: task_definition[:container_definitions],
        family: task_definition[:family],
        task_role_arn: task_definition[:task_role_arn],
        volumes: task_definition[:volumes]
      )

      result[:task_definition]
    end

    # @param [String] service
    # @return [String]
    def register_clone_task(service)
      result = @ecs.describe_services(
        cluster: @cluster,
        services: [service]
      )

      result[:services].each do |svc|
        next unless svc[:service_name] == service

        result = @ecs.describe_task_definition(
          task_definition: svc[:task_definition]
        )

        return register_task_hash(result[:task_definition].to_hash)
      end

      raise ServiceNotFoundError, "'#{service}' service is not found."
    end

    # @param [String] service
    # @param [Aws::ECS::Types::TaskDefinition] task_definition
    # @return [String]
    def update_service(service, task_definition = nil, wait = true)
      task_definition = register_clone_task(service) if task_definition.nil?
      result = @ecs.update_service(
        cluster: @cluster,
        service: service,
        task_definition: task_definition[:family] + ':' + task_definition[:revision].to_s
      )

      wait_for_deploy(service, result.service.task_definition) if wait
      result.service.service_arn
    end

    private

    # @param [Array, Hash] variables
    # @param [Hash] replace_variables
    def replace_parameter_variables!(variables, replace_variables = {})
      for variable in variables do
        if variable.class == Array || variable.class == Hash
          replace_parameter_variables!(variable, replace_variables)
        elsif variable.class == String
          replace_variables.each do |replace_key, replace_value|
            variable.gsub!("{{#{replace_key}}}", replace_value)
          end
        end
      end
    end

    # @param [Hash] task_definition
    def decrypt_environment_variables!(task_definition)
      raise TaskDefinitionValidateError, '\'container_definition\' is undefined.' unless task_definition.key?(:container_definitions)
      task_definition[:container_definitions].each do |container_definition|
        next unless container_definition.key?(:environment)

        container_definition[:environment].each do |environment|
          if environment[:value].class == String
            match = environment[:value].match(ENCRYPT_PATTERN)
            environment[:value] = decrypt(match[0]) if match
          else
            # https://github.com/naomichi-y/ecs_deployer/issues/6
            environment[:value] = environment[:value].to_s
          end
        end
      end
    end

    # @param [String] service
    # @return [Aws::ECS::Types::Service]
    def service_status(service)
      status = nil
      result = @ecs.describe_services(
        cluster: @cluster,
        services: [service]
      )
      result[:services].each do |svc|
        next unless svc[:service_name] == service
        status = svc
        break
      end

      raise ServiceNotFoundError, "'#{service}' service is not found." if status.nil?

      status
    end

    # @param [String] service
    # @param [String] task_definition_arn
    def detect_stopped_task(service, task_definition_arn)
      stopped_tasks = @ecs.list_tasks(
        cluster: @cluster,
        service_name: service,
        desired_status: 'STOPPED'
      ).task_arns

      return if stopped_tasks.size.zero?

      description_tasks = @ecs.describe_tasks(
        cluster: @cluster,
        tasks: stopped_tasks
      ).tasks

      description_tasks.each do |task|
        raise TaskStoppedError, task.stopped_reason if task.task_definition_arn == task_definition_arn
      end
    end

    # @param [String] service
    # @param [String] task_definition_arn
    # @return [Hash]
    def deploy_status(service, task_definition_arn)
      detect_stopped_task(service, task_definition_arn)

      # Get current tasks
      result = @ecs.list_tasks(
        cluster: @cluster,
        service_name: service,
        desired_status: 'RUNNING'
      )

      raise TaskRunningError, 'Running task not found.' if result[:task_arns].size.zero?

      result = @ecs.describe_tasks(
        cluster: @cluster,
        tasks: result[:task_arns]
      )

      new_running_count = 0
      task_status_logs = []

      result[:tasks].each do |task|
        new_running_count += 1 if task_definition_arn == task[:task_definition_arn] && task[:last_status] == 'RUNNING'
        task_status_logs << "  #{task[:task_definition_arn]} [#{task[:last_status]}]"
      end

      {
        current_running_count: result[:tasks].size,
        new_running_count: new_running_count,
        task_status_logs: task_status_logs
      }
    end

    # @param [String] service
    # @param [String] task_definition_arn
    def wait_for_deploy(service, task_definition_arn)
      service_status = service_status(service)

      wait_time = 0
      @logger.info 'Start deploying...'

      loop do
        sleep(@pauling_interval)
        wait_time += @pauling_interval
        result = deploy_status(service, task_definition_arn)

        @logger.info "Deploying... [#{result[:new_running_count]}/#{result[:current_running_count]}] (#{wait_time} seconds elapsed)"
        @logger.info "New task: #{task_definition_arn}"
        @logger.info LOG_SEPARATOR

        result[:task_status_logs].each do |log|
          @logger.info log
        end

        @logger.info LOG_SEPARATOR

        if result[:new_running_count] == result[:current_running_count]
          @logger.info "Service update succeeded. [#{result[:new_running_count]}/#{result[:current_running_count]}]"
          @logger.info "New task definition: #{task_definition_arn}"

          break
        else
          @logger.info 'You can stop process with Ctrl+C. Deployment will continue.'

          if wait_time > @wait_timeout
            @logger.info "New task definition: #{task_definition_arn}"
            raise DeployTimeoutError, 'Service is being updating, but process is timed out.'
          end
        end
      end
    end
  end
end
