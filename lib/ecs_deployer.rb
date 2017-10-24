require 'ecs_deployer/client'
require 'ecs_deployer/cli'
require 'ecs_deployer/error'
require 'ecs_deployer/scheduled_task/client'
require 'ecs_deployer/scheduled_task/target'
require 'ecs_deployer/version'

module EcsDeployer
  class ClusterNotFoundError < EcsDeployer::Error; end
  class ServiceNotFoundError < EcsDeployer::Error; end
  class TaskRunningError < EcsDeployer::Error; end
  class TaskDefinitionValidateError < EcsDeployer::Error; end
  class TaskStoppedError < EcsDeployer::Error; end
  class KmsEncryptError < EcsDeployer::Error; end
  class KmsDecryptError < EcsDeployer::Error; end
  class DeployTimeoutError < EcsDeployer::Error; end
end
