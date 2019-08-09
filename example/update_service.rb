require 'bundler/setup'
require 'ecs_deployer'

client = EcsDeployer::Client.new(ENV['ECS_CLUSTER'])
task_definition = EcsDeployer::Task::Client.new.register(File.expand_path('example/conf/task.yml'), tag: 'latest')
service = client.service.update(ENV['ECS_SERVICE'], task_definition)

puts service.service_arn
