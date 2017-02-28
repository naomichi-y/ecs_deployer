require 'oj'

module EcsDeployer
  class Commander
    # @param [RuntimeCommand::Builder] runtime
    # @param [Hash] options
    # @return EcsDeployer::Commander
    def initialize(runtime, options = {})
      @runtime = runtime
      @options = options
    end

    # @param [String] service
    # @param [Hash] options
    # @return [Hash]
    def update_service(service, options = {})
      options['service'] = service
      exec('update-service', options)
    end

    # @param [Hash] options
    # @return [Hash]
    def list_tasks(options = {})
      exec('list-tasks', options)
    end

    # @param [Array] tasks
    # @param [Hash] options
    # @return [Hash]
    def describe_tasks(tasks, options = {})
      options['tasks'] = tasks.join(' ')
      exec('describe-tasks', options)
    end

    # @param [String] task_definition
    # @param [Hash] options
    # @return [Hash]
    def describe_task_definition(task_definition, options = {})
      options['task-definition'] = task_definition
      exec('describe-task-definition', options)
    end

    # @param [Array] services
    # @param [Hash] options
    # @return [Hash]
    def describe_services(services, options = {})
      options['services'] = services.join(' ')
      exec('describe-services', options)
    end

    # @param [String] family
    # @param [Hash] container_definitions
    # @param [Hash] options
    # @return [Hash]
    def register_task_definition(family, container_definitions, options = {})
      options['family'] = family
      options['container-definitions'] = '"' + Oj.dump(container_definitions).gsub('"', '\\"') + '"'
      exec('register-task-definition', options)
    end

    # @return [String]
    def log
      @runtime.buffered_log
    end

    private
    # @param [String] command
    # @param [Hash] params
    # @return [Hash]
    def exec(command, params)
      arg = ''
      params.each do |name, value|
        arg << "--#{name} #{value} "
      end

      arg << "--profile #{params[:profile]} " if params.has_key?(:profile)
      arg << "--region #{params[:region]} " if params.has_key?(:region)

      command = "aws ecs #{command} #{arg}"
      result = @runtime.exec(command)

      raise CommandError.new unless result.buffered_stderr.empty?

      Oj.load(result.buffered_stdout)
    end
  end
end
