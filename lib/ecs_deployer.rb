require 'ecs_deployer/version'
require 'ecs_deployer/client'
require 'ecs_deployer/error'

module EcsDeployer
  class ServiceNotFoundError < EcsDeployer::Error; end
  class TaskNotFoundError < EcsDeployer::Error; end
  class DeployTimeoutError < EcsDeployer::Error; end
end
