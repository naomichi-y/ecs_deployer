require 'thor'

module EcsDeployer
  class CLI < Thor
    desc 'task_register', 'Create new task definition'
    option :path, required: true
    def task_register
      path = File.expand_path(options[:path], Dir.pwd)

      deployer = EcsDeployer::Client.new
      result = deployer.register_task(path)

      puts "Registered task: #{result}"
    end

    desc 'update_service', 'Update service difinition.'
    option :cluster, required: true
    option :service, required: true
    option :wait, type: :boolean, default: true
    option :timeout, type: :numeric, default: EcsDeployer::Client::DEPLOY_TIMEOUT
    def update_service
      deployer = EcsDeployer::Client.new
      result = deployer.update_service(
        options[:cluster],
        options[:service],
        options[:wait],
        options[:timeout]
      )

      puts "Update service: #{result}"
    end
  end
end
