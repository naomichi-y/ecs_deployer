require 'bundler/setup'
require 'ecs_deployer'

task_path = File.expand_path('./fixtures/task.yml', File.dirname(File.realpath(__FILE__)))
task_path = '/Users/naomichi/Projects/sandbox-ecs/config/deploy/production.yml'

ecs_deployer = EcsDeployer::Client.new
ecs_deployer.register_task(task_path)
ecs_deployer.update_service('sandbox', 'production')
#ecs_deployer.log
