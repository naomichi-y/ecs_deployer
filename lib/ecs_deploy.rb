require 'ecs_deploy/version'
require 'ecs_deploy/client'
require 'ecs_deploy/error'

module EcsDeploy
  class ServiceNotFoundError < EcsDeploy::Error; end
  class TaskNotFoundError < EcsDeploy::Error; end
  class DeployTimeoutError < EcsDeploy::Error; end
end
