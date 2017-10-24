require 'bundler/setup'
require 'ecs_deployer'

path = File.expand_path('../spec/fixtures/task.yml', File.dirname(File.realpath(__FILE__)))

cluster = 'sandbox'
service = 'development'
# rule = 'cron-test'
# target = 'program'

deployer = EcsDeployer::Client.new(cluster)
task_definition = deployer.register_task(path, tag: 'latest')
# scheduled_task = deployer.scheduled_task
#
# target_builder = deployer.scheduled_task.target_builder(target)
# target_builder.task_definition_arn = task_definition.task_definition_arn
# target_builder.task_count = 2

# scheduled_task.update(rule, 'cron(0 * * * ? *)', [target_builder.to_hash])
deployer.update_service(service, task_definition)
