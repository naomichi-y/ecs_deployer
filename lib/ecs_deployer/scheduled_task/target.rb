module EcsDeployer
  module ScheduledTask
    class Target
      attr_reader :id
      attr_accessor :arn, :role_arn, :task_definition_arn, :task_count

      # @param [String] cluster
      # @param [String] id
      # @param [String] role
      # @param [Hash] aws_options
      # @return EcsDeployer::ScheduledTask::Target]
      def initialize(cluster, id, role = nil, aws_options = {})
        ecs = Aws::ECS::Client.new(aws_options)
        clusters = ecs.describe_clusters(clusters: [cluster]).clusters
        raise ClusterNotFoundError, "Cluster does not eixst. [#{cluster}]" if clusters.count.zero?

        @id = id
        @arn = clusters[0].cluster_arn
        @role_arn = Aws::IAM::Role.new(role, @aws_options).arn unless role.nil?
        @task_count = 1
      end

      # @return [Hash]
      def to_hash
        {
          id: @id,
          arn: @arn,
          role_arn: @role_arn,
          ecs_parameters: {
            task_definition_arn: @task_definition_arn,
            task_count: @task_count
          }
        }
      end
    end
  end
end
