require 'yaml'
require 'oj'
require 'aws-sdk'
require 'runtime_command'

module EcsDeployer
  class Client
    PAULING_INTERVAL = 20

    attr_reader :commander

    # @param [Hash] options
    # @option options [String] :profile
    # @option options [String] :region
    # @return [EcsDeployer::Client]
    def initialize(options = {})
      @command = RuntimeCommand::Builder.new
      @family = ''
      @revision = ''
      @new_task_definition_arn = ''
      @commander = Aws::ECS::Client.new(options)
    end

    # @param [String] task_path
    # @return [String]
    def register_task(task_path)
      raise IOError.new("File does not exist. [#{task_path}]") if !File.exist?(task_path)
      register_task_hash(YAML.load(File.read(task_path)))
    end

    # @param [Hash] task_hash
    # @return [String]
    def register_task_hash(task_hash)
      task_hash = Oj.load(Oj.dump(task_hash), symbol_keys: true)

      result = @commander.register_task_definition({
        container_definitions: task_hash[:container_definitions],
        family: task_hash[:family],
        task_role_arn: task_hash[:task_role_arn]
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

      result = @commander.describe_services({
        cluster: cluster,
        services: [service]
      })

      result[:services].each do |svc|
        if svc[:service_name] == service
          result = @commander.describe_task_definition({
            task_definition: svc[:task_definition]
          })
          @new_task_definition_arn = register_task_hash(result[:task_definition])
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
      register_clone_task(service) if @new_task_definition_arn.empty?

      @commander.update_service({
        cluster: cluster,
        service: service,
        task_definition: @family + ':' + @revision.to_s
      })
      wait_for_deploy(cluster, service, timeout) if wait
    end

    private
    # @param [String] cluster
    # @param [String] service
    # @param [Fixnum] timeout
    def wait_for_deploy(cluster, service, timeout)
      detected_service = false

      result = @commander.describe_services({
        cluster: cluster,
        services: [service]
      })
      result[:services].each do |svc|
        next unless svc[:service_name] == service
        detected_service = true

        result = @commander.describe_task_definition({
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
            result = @commander.list_tasks({
              cluster: cluster,
              service_name: service,
              desired_status: 'RUNNING'
            })

            raise TaskNotFoundError.new('Desired count is 0.') if result[:task_arns].size == 0

            new_running_count = 0
            result = @commander.describe_tasks({
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
