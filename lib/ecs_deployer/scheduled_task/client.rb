require 'aws-sdk'

module EcsDeployer
  module ScheduledTask
    class Client
      def initialize(cluster, aws_options = {})
        @cluster = cluster
        @cloudwatch_events = Aws::CloudWatchEvents::Client.new(aws_options)
        @aws_options = aws_options
      end

      def exist_rule?(rule)
        @cloudwatch_events.describe_rule(name: rule)
        true
      rescue Aws::CloudWatchEvents::Errors::ResourceNotFoundException
        false
      end

      def target_builder(id, role = 'ecsEventsRole')
        EcsDeployer::ScheduledTask::Target.new(@cluster, id, role, @aws_options)
      end

      def update(rule, schedule_expression, targets)
        @cloudwatch_events.put_rule(
          name: rule,
          schedule_expression: schedule_expression,
          state: 'ENABLED'
        )
        begin
          @cloudwatch_events.put_targets(
            rule: rule,
            targets: targets
          )
        rescue => e
          @cloudwatch_events.delete_rule(name: rule)
          raise e
        end
      end
    end
  end
end
