require 'yaml'
require 'oj'
require 'aws-sdk'
require 'runtime_command'

module EcsDeployer
  class Client
    PAULING_INTERVAL = 20

    attr_reader :cli

    # @param [Hash] options
    # @option options [String] :profile
    # @option options [String] :region
    # @return [EcsDeployer::Client]
    def initialize(options = {})
      @command = RuntimeCommand::Builder.new
      @family = ''
      @revision = ''
      @new_task_definition_arn = ''
      @cli = Aws::ECS::Client.new(options)
      @kms = Aws::KMS::Client.new(options)
    end

    # @param [String] path
    # @return [String]
    def register_task(path)
      raise IOError.new("File does not exist. [#{path}]") if !File.exist?(path)
      register_task_hash(YAML.load(File.read(path)))
    end

    # @param [Hash] task_definition
    # @return [String]
    def register_task_hash(task_definition)
      task_definition = Oj.load(Oj.dump(task_definition), symbol_keys: true)
      decrypt_environment_variables!(task_definition)

      result = @cli.register_task_definition({
        container_definitions: task_definition[:container_definitions],
        family: task_definition[:family],
        task_role_arn: task_definition[:task_role_arn]
      })

      @family = result[:task_definition][:family]
      @revision = result[:task_definition][:revision]
      @new_task_definition_arn = result[:task_definition][:task_definition_arn]
    end

    # @param [String] cluster
    # @param [String] service
    # @return [String]
    def register_clone_task(cluster, service)
      detected_service = false

      result = @cli.describe_services({
        cluster: cluster,
        services: [service]
      })

      result[:services].each do |svc|
        if svc[:service_name] == service
          result = @cli.describe_task_definition({
            task_definition: svc[:task_definition]
          })
          @new_task_definition_arn = register_task_hash(result[:task_definition].to_hash)
          detected_service = true
          break
        end
      end

      raise ServiceNotFoundError.new("'#{service}' service is not found.") unless detected_service

      @new_task_definition_arn
    end

    # @param [String] cluster
    # @param [String] service
    # @param [Fixnum] timeout
    def update_service(cluster, service, wait = true, timeout = 600)
      register_clone_task(cluster, service) if @new_task_definition_arn.empty?

      @cli.update_service({
        cluster: cluster,
        service: service,
        task_definition: @family + ':' + @revision.to_s
      })
      wait_for_deploy(cluster, service, timeout) if wait
    end

    private
    # @param [Hash] task_definition
    def decrypt_environment_variables!(task_definition)
      raise TaskDefinitionValidateError.new('\'container_definition\' is undefined.') unless task_definition.has_key?(:container_definitions)
      task_definition[:container_definitions].each do |container_definition|
        next unless container_definition.has_key?(:environment)

        container_definition[:environment].each do |environment|
          if match = environment[:value].match(/^\${(.+)}$/)
            begin
              environment[:value] = @kms.decrypt(ciphertext_blob: Base64.strict_decode64(match[1])).plaintext
            rescue => e
              raise KmsDecryptError.new(e.to_s)
            end
          end
        end
      end
    end

    # @param [String] cluster
    # @param [String] service
    # @param [Fixnum] timeout
    def wait_for_deploy(cluster, service, timeout)
      detected_service = false

      result = @cli.describe_services({
        cluster: cluster,
        services: [service]
      })
      result[:services].each do |svc|
        next unless svc[:service_name] == service
        detected_service = true

        result = @cli.describe_task_definition({
          task_definition: svc[:task_definition]
        })

        if svc[:desired_count] > 0
          running_new_task = false
          wait_time = 0
          @command.puts 'Start deploing...'

          begin
            sleep(PAULING_INTERVAL)
            wait_time += PAULING_INTERVAL

            # Get current tasks
            result = @cli.list_tasks({
              cluster: cluster,
              service_name: service,
              desired_status: 'RUNNING'
            })

            raise TaskNotFoundError.new('Desired count is 0.') if result[:task_arns].size == 0

            new_running_count = 0
            result = @cli.describe_tasks({
              tasks: result[:task_arns],
              cluster: cluster
            })

            result[:tasks].each do |task|
              new_running_count += 1 if @new_task_definition_arn == task[:task_definition_arn]
            end

            current_running_count = result[:tasks].size

            if current_running_count == new_running_count
              @command.puts "Service update succeeded. [#{new_running_count}/#{current_running_count}]"
              @command.puts "New task definition: #{@new_task_definition_arn}"

              running_new_task = true

            else
              @command.puts "Deploying... [#{new_running_count}/#{current_running_count}] (#{wait_time} seconds elapsed)"
              @command.puts "New task: #{@new_task_definition_arn}"
              @command.puts 'You can stop process with Ctrl+C. Deployment will continue.'

              if wait_time > timeout
                @command.puts "New task definition: #{@new_task_definition_arn}"
                raise DeployTimeoutError.new('Service is being updating, but process is timed out.')
              end
            end
          end while !running_new_task
        end

        break
      end

      raise ServiceNotFoundError.new("'#{service}' service is not found.") unless detected_service
    end
  end
end
