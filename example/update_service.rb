require 'bundler/setup'
require 'ecs_deployer'
require 'dotenv'

Dotenv.load
path = File.expand_path(ENV['TASK_PATH'], '.')

deployer = EcsDeployer::Client.new(ENV['CLUSTER'])
task_definition = deployer.task.register(path, tag: 'latest')
deployer.update_service(ENV['SERVICE'], task_definition)
