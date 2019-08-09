require 'bundler/setup'
require 'ecs_deployer'

task_definition = EcsDeployer::Task::Client.new.register(File.expand_path('example/conf/task.yml'), tag: 'latest')
puts task_definition.task_definition_arn
