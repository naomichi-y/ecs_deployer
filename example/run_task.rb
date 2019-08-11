require 'bundler/setup'
require 'ecs_deployer'
require 'yaml'

params = YAML.load(File.read(File.expand_path('example/conf/task.yml')))
params['container_definitions'][0]['command'] = ['echo', 'hello']

client = EcsDeployer::Task::Client.new
task_definition = client.register_hash(params, tag: 'latest')

run_task_response = Aws::ECS::Client.new.run_task(cluster: ENV['ECS_CLUSTER'], task_definition: task_definition.task_definition_arn)
puts run_task_response[:tasks][0][:task_arn]
