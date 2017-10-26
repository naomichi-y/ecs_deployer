require 'aws-sdk'

module EcsDeployer
  module ScheduledTask
    class Client
      # @param [String] cluster
      # @param [Hash] aws_options
      # @return [EcsDeployer::ScheduledTask::Client]
      def initialize(cluster, aws_options = {})
        @cluster = cluster
        @cloud_watch_events = Aws::CloudWatchEvents::Client.new(aws_options)
        @aws_options = aws_options
      end

      # @param [String] rule
      # @return [Bool]
      def exist_rule?(rule)
        @cloud_watch_events.describe_rule(name: rule)
        true
      rescue Aws::CloudWatchEvents::Errors::ResourceNotFoundException
        false
      end

      # @param [String] id
      # @param [String] role
      # @return [EcsDeployer::ScheduledTask::Target]
      def target_builder(id, role = 'ecsEventsRole')
        EcsDeployer::ScheduledTask::Target.new(@cluster, id, role, @aws_options)
      end

      # @param [String] rule
      # @param [String] schedule_expression
      # @param [Array] targets
      # @return [CloudWatchEvents::Types::PutRuleResponse]
      def update(rule, schedule_expression, targets)
        response = @cloud_watch_events.put_rule(
          name: rule,
          schedule_expression: schedule_expression,
          state: 'ENABLED'
        )
        begin
          @cloud_watch_events.put_targets(
            rule: rule,
            targets: targets
          )

          response
        rescue => e
          @cloud_watch_events.delete_rule(name: rule)
          raise e
        end
      end
    end
  end
end
