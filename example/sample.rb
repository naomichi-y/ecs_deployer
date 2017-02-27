require 'bundler/setup'
require 'ecs_deploy'

task_path = File.expand_path('./fixtures/task.yml', File.dirname(File.realpath(__FILE__)))

ecs_deploy = EcsDeploy::Client.new('cluster_name')
ecs_deploy.register_task(task_path)
ecs_deploy.update_service('application')
