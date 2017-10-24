require 'bundler/setup'
require 'ecs_deployer'
require 'dotenv'

Dotenv.load
path = File.expand_path(ENV['TASK_PATH'], '.')

deployer = EcsDeployer::Client.new(ENV['CLUSTER'])
task_definition = deployer.register_task(path, tag: 'latest')

scheduled_task = deployer.scheduled_task
target_builder = scheduled_task.target_builder(ENV['SCHEDULED_TASK_TARGET'])
target_builder.task_definition_arn = task_definition.task_definition_arn

scheduled_task.update(ENV['SCHEDULED_TASK_RULE'], 'cron(* * * * ? *)', [target_builder.to_hash])
