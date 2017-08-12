require 'yaml'
require 'oj'
require 'aws-sdk'
require 'runtime_command'
require 'base64'

module EcsDeployer
  class Client
    LOG_SEPARATOR = '-' * 96
    ENCRYPT_PATTERN = /^\${(.+)}$/

    attr_reader :cli
    attr_accessor :timeout, :pauling_interval

    # @param [Hash] aws_options
    # @param [Hash] runtime_options
    # @return [EcsDeployer::Client]
    def initialize(aws_options = {}, runtime_options = {})
      @runtime = RuntimeCommand::Builder.new(runtime_options)
      @cli = Aws::ECS::Client.new(aws_options)
      @kms = Aws::KMS::Client.new(aws_options)
      @timeout = 600
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
    # @return [String]
    def register_task_hash(task_definition, replace_variables = {})
      task_definition = Oj.load(Oj.dump(task_definition), symbol_keys: true)

      replace_parameter_variables!(task_definition, replace_variables)
      decrypt_environment_variables!(task_definition)

      result = @cli.register_task_definition(
        container_definitions: task_definition[:container_definitions],
        family: task_definition[:family],
        task_role_arn: task_definition[:task_role_arn],
        volumes: task_definition[:volumes]
      )

      @family = result[:task_definition][:family]
      @revision = result[:task_definition][:revision]
      @new_task_definition_arn = result[:task_definition][:task_definition_arn]
    end

    # @param [String] cluster
    # @param [String] service
    # @return [String]
    def register_clone_task(cluster, service)
      detected_service = false

      result = @cli.describe_services(
        cluster: cluster,
        services: [service]
      )

      result[:services].each do |svc|
        next unless svc[:service_name] == service

        result = @cli.describe_task_definition(
          task_definition: svc[:task_definition]
        )
        @new_task_definition_arn = register_task_hash(result[:task_definition].to_hash)
        detected_service = true
        break
      end

      raise ServiceNotFoundError, "'#{service}' service is not found." unless detected_service

      @new_task_definition_arn
    end

    # @param [String] cluster
    # @param [String] service
    # @return [String]
    def update_service(cluster, service, wait = true)
      register_clone_task(cluster, service) if @new_task_definition_arn.nil?

      result = @cli.update_service(
        cluster: cluster,
        service: service,
        task_definition: @family + ':' + @revision.to_s
      )
      wait_for_deploy(cluster, service) if wait
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

    # @param [String] cluster
    # @param [String] service
    # @return [Aws::ECS::Types::Service]
    def service_status(cluster, service)
      status = nil
      result = @cli.describe_services(
        cluster: cluster,
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

    # @param [String] cluster
    # @param [String] service
    # @return [Hash]
    def deploy_status(cluster, service)
      # Get current tasks
      result = @cli.list_tasks(
        cluster: cluster,
        service_name: service,
        desired_status: 'RUNNING'
      )

      raise TaskRunningError, 'Running task not found.' if result[:task_arns].size.zero?

      result = @cli.describe_tasks(
        cluster: cluster,
        tasks: result[:task_arns]
      )

      new_running_count = 0
      task_status_logs = []

      result[:tasks].each do |task|
        new_running_count += 1 if @new_task_definition_arn == task[:task_definition_arn]
        task_status_logs << "  #{task[:task_definition_arn]} [#{task[:last_status]}]"
      end

      {
        current_running_count: result[:tasks].size,
        new_running_count: new_running_count,
        task_status_logs: task_status_logs
      }
    end

    # @param [String] cluster
    # @param [String] service
    def wait_for_deploy(cluster, service)
      service_status = service_status(cluster, service)
      raise TaskDesiredError, 'Task desired by service is 0.' if service_status[:desired_count].zero?

      wait_time = 0
      @runtime.puts 'Start deploying...'

      loop do
        sleep(@pauling_interval)
        wait_time += @pauling_interval
        result = deploy_status(cluster, service)

        if result[:new_running_count] == result[:current_running_count]
          @runtime.puts "Service update succeeded. [#{result[:new_running_count]}/#{result[:current_running_count]}]"
          @runtime.puts "New task definition: #{@new_task_definition_arn}"

          break

        else
          @runtime.puts "Deploying... [#{result[:new_running_count]}/#{result[:current_running_count]}] (#{wait_time} seconds elapsed)"
          @runtime.puts "New task: #{@new_task_definition_arn}"
          @runtime.puts LOG_SEPARATOR

          result[:task_status_logs].each do |log|
            @runtime.puts log
          end

          @runtime.puts LOG_SEPARATOR
          @runtime.puts 'You can stop process with Ctrl+C. Deployment will continue.'

          if wait_time > @timeout
            @runtime.puts "New task definition: #{@new_task_definition_arn}"
            raise DeployTimeoutError, 'Service is being updating, but process is timed out.'
          end
        end
      end
    end
  end
end
