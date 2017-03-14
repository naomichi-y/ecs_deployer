require 'ecs_deployer/version'
require 'ecs_deployer/client'
require 'ecs_deployer/error'
require 'ecs_deployer/cli'

module EcsDeployer
  class ServiceNotFoundError < EcsDeployer::Error; end
  class TaskRunningError < EcsDeployer::Error; end
  class TaskDefinitionValidateError < EcsDeployer::Error; end
  class TaskDesiredError < EcsDeployer::Error; end
  class KmsEncryptError < EcsDeployer::Error; end
  class KmsDecryptError < EcsDeployer::Error; end
  class DeployTimeoutError < EcsDeployer::Error; end
end
