require 'bundler/setup'
require 'ecs_deployer'

path = File.expand_path('../spec/fixtures/task.yml', File.dirname(File.realpath(__FILE__)))
path = '/Users/naomichi_yamakita_pn082/Projects/nichigas-sandbox/config/deploy/development.yml'

deployer = EcsDeployer::Client.new('sandbox')
task_definition = deployer.register_task(path, tag: 'latest')
deployer.update_service('development', task_definition)
