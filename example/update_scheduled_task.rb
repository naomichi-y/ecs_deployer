require 'bundler/setup'
require 'ecs_deployer'

path = File.expand_path('../spec/fixtures/scheduled_task.yml', File.dirname(File.realpath(__FILE__)))

cluster = 'test'
rule = 'curl'
target = 'worker'

deployer = EcsDeployer::Client.new(cluster)
task_definition = deployer.register_task(path, tag: 'latest')

scheduled_task = deployer.scheduled_task
target_builder = scheduled_task.target_builder(target)
target_builder.task_definition_arn = task_definition.task_definition_arn

scheduled_task.update(rule, 'cron(* * * * ? *)', [target_builder.to_hash])
