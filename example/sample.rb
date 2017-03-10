require 'bundler/setup'
require 'ecs_deployer'

task_path = File.expand_path('./fixtures/task.yml', File.dirname(File.realpath(__FILE__)))
task_path = '/Users/naomichi_yamakita_pn082/Projects/sandbox-ecs/config/deploy/production.yml'

deployer = EcsDeployer::Client.new
deployer.register_task(task_path)
# ecs_deployer.update_service('sandbox', 'production')
