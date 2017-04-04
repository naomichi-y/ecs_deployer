require 'bundler/setup'
require 'ecs_deployer'

path = File.expand_path('../spec/fixtures/task.yml', File.dirname(File.realpath(__FILE__)))

deployer = EcsDeployer::Client.new
deployer.register_task(path, tag: 'latest')
# deployer.update_service('sandbox', 'production')
