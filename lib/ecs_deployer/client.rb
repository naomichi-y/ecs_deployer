require 'yaml'
require 'oj'
require 'aws-sdk'
require 'runtime_command'
require 'base64'

module EcsDeployer
  class Client
    LOG_SEPARATOR = '-' * 96
    PAULING_INTERVAL = 20
    DEPLOY_TIMEOUT = 600
    ENCRYPT_PATTERN = /^\${(.+)}$/

    attr_reader :cli

    # @param [Hash] aws_options
    # @option aws_options [String] :profile
    # @option aws_options [String] :region
    # @return [EcsDeployer::Client]
    def initialize(aws_options = {})
      @command = RuntimeCommand::Builder.new
      @cli = Aws::ECS::Client.new(aws_options)
      @kms = Aws::KMS::Client.new(aws_options)
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
    # @return [String]
    def register_task(path)
      raise IOError, "File does not exist. [#{path}]" unless File.exist?(path)

      register_task_hash(YAML.load(File.read(path)))
    end

    # @param [Hash] task_definition
    # @return [String]
    def register_task_hash(task_definition)
      task_definition = Oj.load(Oj.dump(task_definition), symbol_keys: true)
      decrypt_environment_variables!(task_definition)

      result = @cli.register_task_definition(
        container_definitions: task_definition[:container_definitions],
        family: task_definition[:family],
        task_role_arn: task_definition[:task_role_arn]
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
    # @param [Fixnum] timeout
    # @return [String]
    def update_service(cluster, service, wait = true, timeout = DEPLOY_TIMEOUT)
      register_clone_task(cluster, service) if @new_task_definition_arn.nil?

      result = @cli.update_service(
        cluster: cluster,
        service: service,
        task_definition: @family + ':' + @revision.to_s
      )
      wait_for_deploy(cluster, service, timeout) if wait
      result.service.service_arn
    end

    private

    # @param [Hash] task_definition
    def decrypt_environment_variables!(task_definition)
      raise TaskDefinitionValidateError, '\'container_definition\' is undefined.' unless task_definition.key?(:container_definitions)
      task_definition[:container_definitions].each do |container_definition|
        next unless container_definition.key?(:environment)

        container_definition[:environment].each do |environment|
          match = environment[:value].match(ENCRYPT_PATTERN)
          environment[:value] = decrypt(match[0]) if match
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

      raise TaskNotFoundError, 'Desired count is 0.' if result[:task_arns].size.zero?

      result = @cli.describe_tasks(
        cluster: cluster,
        tasks: result[:task_arns]
      )

      new_running_count = 0
      task_status_logs = ''

      result[:tasks].each do |task|
        new_running_count += 1 if @new_task_definition_arn == task[:task_definition_arn]
        task_status_logs << "  #{task[:task_definition_arn]} [#{task[:last_status]}]\n"
      end

      {
        current_running_count: result[:tasks].size,
        new_running_count: new_running_count,
        task_status_logs: task_status_logs
      }
    end

    # @param [String] cluster
    # @param [String] service
    # @param [Fixnum] timeout
    def wait_for_deploy(cluster, service, timeout)
      service_status = service_status(cluster, service)
      raise TaskDesiredError, 'Task desired by service is 0.' if service_status[:desired_count].zero?

      wait_time = 0
      @command.puts 'Start deploing...'

      loop do
        sleep(PAULING_INTERVAL)
        wait_time += PAULING_INTERVAL
        result = deploy_status(cluster, service)

        if result[:new_running_count] == result[:current_running_count]
          @command.puts "Service update succeeded. [#{result[:new_running_count]}/#{result[:current_running_count]}]"
          @command.puts "New task definition: #{@new_task_definition_arn}"

          break

        else
          @command.puts "Deploying... [#{result[:new_running_count]}/#{result[:current_running_count]}] (#{wait_time} seconds elapsed)"
          @command.puts "New task: #{@new_task_definition_arn}"
          @command.puts LOG_SEPARATOR
          @command.puts result[:task_status_logs]
          @command.puts LOG_SEPARATOR
          @command.puts 'You can stop process with Ctrl+C. Deployment will continue.'

          if wait_time > timeout
            @command.puts "New task definition: #{@new_task_definition_arn}"
            raise DeployTimeoutError, 'Service is being updating, but process is timed out.'
          end
        end
      end
    end
  end
end
