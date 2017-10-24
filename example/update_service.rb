require 'bundler/setup'
require 'ecs_deployer'

path = File.expand_path('../spec/fixtures/task.yml', File.dirname(File.realpath(__FILE__)))

cluster = 'test'
service = 'development'

deployer = EcsDeployer::Client.new(cluster)
task_definition = deployer.register_task(path, tag: 'latest')
deployer.update_service(service, task_definition)
