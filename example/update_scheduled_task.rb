require 'bundler/setup'
require 'ecs_deployer'
require 'config'

Config.load_and_set_settings('config.yml', 'config.local.yml')
task_path = File.expand_path(Settings.scheduled_task_path)

deployer = EcsDeployer::Client.new(Settings.cluster)
task_definition = deployer.task.register(task_path, tag: 'latest')

scheduled_task = deployer.scheduled_task
target_builder = scheduled_task.target_builder(Settings.scheduled_task_target_id)
target_builder.task_definition_arn = task_definition.task_definition_arn
target_builder.override_container('rails', ['curl', 'http://153.122.13.159/'])

puts scheduled_task.update(Settings.scheduled_task_rule, 'cron(* * * * ? *)', [target_builder.to_hash])
