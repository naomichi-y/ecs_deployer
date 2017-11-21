require 'aws-sdk'

module EcsDeployer
  module Service
    class Client
      LOG_SEPARATOR = '-' * 96

      attr_accessor :wait_timeout, :polling_interval

      # @param [String] cluster
      # @param [Logger] logger
      # @param [Hash] aws_options
      # @return [EcsDeployer::Service::Client]
      def initialize(cluster, logger, aws_options = {})
        @cluster = cluster
        @logger = logger

        @ecs = Aws::ECS::Client.new(aws_options)
        @task = EcsDeployer::Task::Client.new(aws_options)

        @wait_timeout = 900
        @polling_interval = 20
      end

      # @param [String] service
      # @param [Aws::ECS::Types::TaskDefinition] task_definition
      # @return [Aws::ECS::Types::Service]
      def update(service, task_definition = nil, wait = true)
        task_definition = @task.register_clone(@cluster, service) if task_definition.nil?
        result = @ecs.update_service(
          cluster: @cluster,
          service: service,
          task_definition: task_definition[:family] + ':' + task_definition[:revision].to_s
        )

        wait_for_deploy(service, result.service.task_definition) if wait
        result.service
      end

      # @param [String] service
      # @return [Bool]
      def exist?(service)
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

        status.nil? ? false : true
      end

      private

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
        raise ServiceNotFoundError, "'#{service}' service is not found." unless exist?(service)

        wait_time = 0
        @logger.info 'Start deploying...'

        loop do
          sleep(@polling_interval)
          wait_time += @polling_interval
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
end
