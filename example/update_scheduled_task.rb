require 'bundler/setup'
require 'ecs_deployer'
require 'dotenv'

Dotenv.load
path = File.expand_path(ENV['SCHEDULED_TASK_PATH'], '.')

deployer = EcsDeployer::Client.new(ENV['CLUSTER'])
task_definition = deployer.task.register(path, tag: 'latest')

scheduled_task = deployer.scheduled_task
target_builder = scheduled_task.target_builder(ENV['SCHEDULED_TASK_TARGET'])
target_builder.task_definition_arn = task_definition.task_definition_arn
target_builder.override_command('rails', ['curl', 'http://153.122.13.159/'])

puts scheduled_task.update(ENV['SCHEDULED_TASK_RULE'], 'cron(* * * * ? *)', [target_builder.to_hash])
