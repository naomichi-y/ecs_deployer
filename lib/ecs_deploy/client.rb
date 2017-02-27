require 'yaml'
require 'runtime_command'
require 'ecs_deploy/commander'

module EcsDeploy
  class Client
    PAULING_INTERVAL = 20

    # @param [String] cluster_name
    # @param [Hash] options
    # @option options [String] :profile
    # @option options [String] :region
    # @return [EcsDeploy::Client]
    def initialize(cluster_name, options = {})
      @cluster_name = cluster_name
      @ecs_command = Commander.new(cluster_name, options)
      @family_name = ''
      @revision = ''
      @new_task_definition_arn = ''
    end

    # @param [String] task_path
    # @return [String]
    def register_task(task_path)
      raise IOError.new("File does not exist. [#{task_path}]") if !File.exist?(task_path)
      register_task_process(YAML.load(File.read(task_path)))
    end

    # @param [String] service_name
    # @return [String]
    def register_clone_task(service_name)
      detected_service = false

      result = @ecs_command.describe_services(service_name)
      result['services'].each do |service|
        if service['serviceName'] == service_name
          result = @ecs_command.describe_task_definition(service['taskDefinition'])
          @new_task_definition_arn = register_task_process(result['taskDefinition'])
          detected_service = true
          break
        end
      end

      raise ServiceNotFoundError.new("'#{service_name}' service is not found.") unless detected_service

      @new_task_definition_arn
    end

    # @param [String] service_name
    # @param [Fixnum] timeout
    def update_service(service_name, wait = true, timeout = 300)
      register_clone_task(service_name) if @new_task_definition_arn.empty?
      @ecs_command.update_service(service_name, @family_name, @revision)
      wait_for_deploy if wait
    end

    private
    def wait_for_deploy(service_name, timeout)
      detected_service = false

      result = @ecs_command.describe_services(service_name)
      result['services'].each do |service|
        next unless service['serviceName'] == service_name
        detected_service = true

        result = @ecs_command.describe_task_definition(service['taskDefinition'])

        if service['desiredCount'] > 0
          running_new_task = false
          wait_time = 0
          puts 'Start deploing...'

          begin
            sleep(PAULING_INTERVAL)
            wait_time += PAULING_INTERVAL

            # Get current tasks
            result = @ecs_command.list_tasks(service_name)

            if result['taskArns'].size > 0
              success_count = 0

              result = @ecs_command.describe_tasks(result['taskArns'])
              result['tasks'].each do |task|
                success_count += 1 if @new_task_definition_arn == task['taskDefinitionArn']
              end

              if result['tasks'].size == success_count
                puts 'Service update succeeded.'
                puts "New task definition: #{@new_task_definition_arn}"

                running_new_task = true
              end
            else
              raise TaskNotFoundError.new('Desired count is 0.')
            end

            if wait_time > timeout
              puts "New task definition: #{@new_task_definition_arn}"
              raise DeployTimeoutError.new('Service is being updating, but process is timed out.')
            end

            puts "Deploying... (#{wait_time} seconds elapsed)"

          end while !running_new_task
        end

        break
      end

      raise ServiceNotFoundError.new("'#{service_name}' service is not found.") unless detected_service
    end

    # @param [Hash] task_definition
    # @return [String]
    def register_task_process(task_definition)
      result = @ecs_command.register_task_definition(
        task_definition['family'],
        task_definition['containerDefinitions']
      )

      @family_name = result['taskDefinition']['family']
      @revision = result['taskDefinition']['revision']
      @new_task_definition_arn = result['taskDefinition']['taskDefinitionArn']
    end
  end

end
