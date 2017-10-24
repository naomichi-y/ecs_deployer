require 'bundler/setup'
require 'ecs_deployer'
require 'logger'

path = File.expand_path('../spec/fixtures/task.yml', File.dirname(File.realpath(__FILE__)))

cluster = 'test'

deployer = EcsDeployer::Client.new(cluster)
task_definition = deployer.register_task(path, tag: 'latest')

logger = Logger.new(STDOUT)
logger.info(task_definition)
