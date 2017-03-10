require 'bundler/setup'
require 'ecs_deployer'

task_path = File.expand_path('./fixtures/task.yml', File.dirname(File.realpath(__FILE__)))

deployer = EcsDeployer::Client.new
deployer.register_task(task_path)
deployer.update_service('sandbox', 'production')
