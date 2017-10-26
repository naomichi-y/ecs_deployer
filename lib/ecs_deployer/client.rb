require 'logger'

module EcsDeployer
  class Client
    # @param [String] cluster
    # @param [Logger] logger
    # @param [Hash] aws_options
    # @return [EcsDeployer::Client]
    def initialize(cluster, logger = nil, aws_options = {})
      @cluster = cluster
      @logger = logger.nil? ? Logger.new(STDOUT) : logger
      @aws_options = aws_options
    end

    # @return [EcsDeployer::Task::Client]
    def task
      EcsDeployer::Task::Client.new(@aws_options)
    end

    # @return [EcsDeployer::ScheduledTask::Client]
    def scheduled_task
      EcsDeployer::ScheduledTask::Client.new(@cluster, @aws_options)
    end

    # @return [EcsDeployer::Service::Client]
    def service
      EcsDeployer::Service::Client.new(@cluster, @logger, @aws_options)
    end
  end
end
