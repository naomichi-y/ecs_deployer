require 'bundler/setup'
require 'ecs_deployer'

path = File.expand_path('../spec/fixtures/task.yml', File.dirname(File.realpath(__FILE__)))
path = '/Users/naomichi_yamakita_pn082/Projects/sandbox-ecs/config/deploy/development.yml'

deployer = EcsDeployer::Client.new
# deployer.register_task(path, tag: 'latest')
# deployer.update_service('sandbox', 'production')
