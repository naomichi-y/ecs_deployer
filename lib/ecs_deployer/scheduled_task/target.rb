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
        @container_overrides = []
      end

      # @param [String] name
      # @param [Array] command
      # @param [Hash] environments
      def override_container(name, command = nil, environments = {})
        override_environments = []
        environments.each do |environment|
          environment.each do |env_name, env_value|
            override_environments << {
              name: env_name,
              value: env_value
            }
          end
        end

        @container_overrides << {
          name: name,
          command: command,
          environment: override_environments
        }
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
          },
          input: {
            containerOverrides: @container_overrides
          }.to_json.to_s
        }
      end
    end
  end
end
