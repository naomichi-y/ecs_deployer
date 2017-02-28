require 'yaml'
require 'runtime_command'
require 'ecs_deployer/commander'

module EcsDeployer
  class Client
    PAULING_INTERVAL = 20

    # @param [String] cluster
    # @param [Hash] options
    # @option options [String] :profile
    # @option options [String] :region
    # @return [EcsDeployer::Client]
    def initialize(cluster, options = {})
      @cluster = cluster
      @runtime = RuntimeCommand::Builder.new
      @ecs_command = Commander.new(@runtime, options)
      @family = ''
      @revision = ''
      @new_task_definition_arn = ''
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
      result = @ecs_command.register_task_definition(task_hash['family'], task_hash['containerDefinitions'])

      @family = result['taskDefinition']['family']
      @revision = result['taskDefinition']['revision']
      @new_task_definition_arn = result['taskDefinition']['taskDefinitionArn']
    end

    # @param [String] service
    # @return [String]
    def register_clone_task(service)
      detected_service = false

      result = @ecs_command.describe_services([service], { 'cluster': @cluster })
      result['services'].each do |svc|
        if svc['serviceName'] == service
          result = @ecs_command.describe_task_definition(svc['taskDefinition'])
          @new_task_definition_arn = register_task_hash(result['taskDefinition'])
          detected_service = true
          break
        end
      end

      raise ServiceNotFoundError.new("'#{service}' service is not found.") unless detected_service

      @new_task_definition_arn
    end

    # @param [String] service
    # @param [Fixnum] timeout
    def update_service(service, wait = true, timeout = 600)
      register_clone_task(service) if @new_task_definition_arn.empty?
      options = {
        'cluster': @cluster,
        'task-definition': @family + ':' + @revision.to_s
      }
      @ecs_command.update_service(service, options)
      wait_for_deploy(service, timeout) if wait
    end

    # @return [String]
    def log
      @ecs_command.log
    end

    private
    def wait_for_deploy(service, timeout)
      detected_service = false

      result = @ecs_command.describe_services([service], { 'cluster': @cluster })
      result['services'].each do |svc|
        next unless svc['serviceName'] == service
        detected_service = true

        result = @ecs_command.describe_task_definition(svc['taskDefinition'])

        if svc['desiredCount'] > 0
          running_new_task = false
          wait_time = 0
          @runtime.puts 'Start deploing...'

          begin
            sleep(PAULING_INTERVAL)
            wait_time += PAULING_INTERVAL

            # Get current tasks
            options = {
              'cluster': @cluster,
              'service-name': service,
              'desired-status': 'RUNNING'
            }
            result = @ecs_command.list_tasks(options)

            raise TaskNotFoundError.new('Desired count is 0.') if result['taskArns'].size == 0

            new_running_count = 0
            result = @ecs_command.describe_tasks(result['taskArns'], { 'cluster': @cluster })

            result['tasks'].each do |task|
              new_running_count += 1 if @new_task_definition_arn == task['taskDefinitionArn']
            end

            current_running_count = result['tasks'].size

            if current_running_count == new_running_count
              @runtime.puts "Service update succeeded. [#{new_running_count}/#{current_running_count}]"
              @runtime.puts "New task definition: #{@new_task_definition_arn}"

              running_new_task = true

            else
              @runtime.puts "Deploying... [#{new_running_count}/#{current_running_count}] (#{wait_time} seconds elapsed)"
              @runtime.puts 'You can stop process with Ctrl+C. Deployment will continue.'

              if wait_time > timeout
                @runtime.puts "New task definition: #{@new_task_definition_arn}"
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
