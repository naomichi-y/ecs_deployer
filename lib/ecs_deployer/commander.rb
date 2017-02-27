require 'oj'
require 'runtime_command'

module EcsDeployer
  class Commander
    # @param [String] cluster_name
    # @param [Hash] options
    # @return EcsDeployer::Commander
    def initialize(cluster_name, options = {})
      @runtime = RuntimeCommand::Builder.new
      @options = options
      @cluster_name = cluster_name
    end

    # @param [String] service_name
    # @param [String] family_name
    # @param [Fixnum] revision
    # @return [Hash]
    def update_service(service_name, family_name, revision)
      args = {
        'cluster': @cluster_name,
        'service':  service_name,
        'task-definition': family_name + ':' + revision.to_s
      }

      exec('update-service', args)
    end

    # @param [String] service_name
    # @return [Hash]
    def list_tasks(service_name)
      args = {
        'cluster': @cluster_name,
        'service-name': service_name,
        'desired-status': 'RUNNING'
      }
      exec('list-tasks', args)
    end

    # @param [Array] tasks
    # @return [Hash]
    def describe_tasks(tasks)
      args = {
        'cluster': @cluster_name,
        'tasks': tasks.join(' ')
      }
      exec('describe-tasks', args)
    end

    # @param [String] task_definition
    # @return [Hash]
    def describe_task_definition(task_definition)
      args = {
        'task-definition': task_definition
      }
      exec('describe-task-definition', args)
    end

    # @param [String] service_name
    # @return [Hash]
    def describe_services(service_name)
      args = {
        'cluster': @cluster_name,
        'services': service_name
      }
      exec('describe-services', args)
    end

    # @param [String] family_name
    # @param [Hash] container_definitions
    # @return [Hash]
    def register_task_definition(family_name, container_definitions)
      args = {
        'family': family_name,
        'container-definitions': '"' + Oj.dump(container_definitions).gsub('"', '\\"') + '"'
      }
      exec('register-task-definition', args)
    end

    private
    # @param [String] command
    # @param [Hash] args
    # @return [Hash]
    def exec(command, args)
      arg = ''
      args.each do |name, value|
        arg << "--#{name} #{value} "
      end

      arg << "--profile #{@options[:profile]} " if @options.has_key?(:profile)
      arg << "--region #{@options[:region]} " if @options.has_key?(:region)

      command = "aws ecs #{command} #{arg}"
      result = @runtime.exec(command)

      raise EcsCommandError.new unless result.buffered_stderr.empty?

      result = result.buffered_stdout
      Oj.load(result)
    end
  end

  class EcsCommandError < RuntimeError; end
end
