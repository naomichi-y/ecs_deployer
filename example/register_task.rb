require 'bundler/setup'
require 'ecs_deployer'
require 'config'

Config.load_and_set_settings('config.yml', 'config.local.yml')

task_path = File.expand_path(Settings.task_path)
deployer = EcsDeployer::Client.new(Settings.cluster)
task_definition = deployer.task.register(task_path, tag: 'latest')

puts task_definition.task_definition_arn
