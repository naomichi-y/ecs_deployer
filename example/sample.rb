require 'bundler/setup'
require 'ecs_deployer'

task_path = File.expand_path('./fixtures/task.yml', File.dirname(File.realpath(__FILE__)))

ecs_deployer = EcsDeployer::Client.new('sandbox-ecs-production')
ecs_deployer.register_task(task_path)
ecs_deployer.update_service('application')
#ecs_deployer.log
