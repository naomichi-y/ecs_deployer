require 'bundler/setup'
require 'ecs_deployer'

task_definition = EcsDeployer::Task::Client.new.register(File.expand_path('example/conf/task.yml'), tag: 'latest')

scheduled_task = EcsDeployer::Client.new(ENV['ECS_CLUSTER']).scheduled_task
target_builder = scheduled_task.target_builder(ENV['ECS_SCHEDULED_TASK_TARGET_ID'])
target_builder.task_definition_arn = task_definition.task_definition_arn
target_builder.override_container('rails', ['curl', 'http://153.122.13.159/'])
target_builder.cloudwatch_event_role_arn = ENV['CLOUDWATCH_EVENT_ARN']

task_definition = scheduled_task.update(
  ENV['ECS_SCHEDULED_TASK_RULE_ID'],
  'cron(* * * * ? *)',
  [target_builder.to_hash],
  description: 'Test task'
)
puts task_definition.rule_arn
