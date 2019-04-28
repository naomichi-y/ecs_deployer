require 'thor'

module EcsDeployer
  class CLI < Thor
    class_option :profile, type: :string
    class_option :region, type: :string

    no_commands do
      def prepare
        @aws_options = {}
        @aws_options[:profile] = options[:profile] if options[:profile]
        @aws_options[:region] = options[:region] if options[:region]

        @logger = Logger.new(STDOUT)

        nil
      end

      def invoke_command(command, *args)
        prepare
        super
      end
    end

    desc 'task-register', 'Create new task definition'
    option :path, required: true
    option :replace_variables, type: :hash, default: {}
    def task_register
      path = File.expand_path(options[:path], Dir.pwd)
      task_client = EcsDeployer::Task::Client.new(@aws_options)
      result = task_client.register(path, options[:replace_variables])

      puts "Registered task: #{result.task_definition_arn}"
    end

    desc 'update-service', 'Update service difinition.'
    option :cluster, required: true
    option :service, required: true
    option :wait, type: :boolean, default: true
    option :wait_timeout, type: :numeric, default: 600
    def update_service
      deploy_client = EcsDeployer::Client.new(options[:cluster], @logger, @aws_options)
      service_client = deploy_client.service
      service_client.wait_timeout = options[:wait_timeout]
      result = service_client.update(options[:service], nil, options[:wait])

      puts "Service has been successfully updated: #{result.service_arn}"
    end

    desc 'encrypt', 'Encrypt value of argument with KMS.'
    option :master_key, required: true
    option :value, required: true
    def encrypt
      cipher = EcsDeployer::Util::Cipher.new(@aws_options)
      puts "Encrypted value: #{cipher.encrypt(options[:master_key], options[:value])}"
    end

    desc 'decrypt', 'Decrypt value of argument with KMS.'
    option :value, required: true
    def decrypt
      cipher = EcsDeployer::Util::Cipher.new(@aws_options)
      puts "Decrypted value: #{cipher.decrypt(options[:value])}"
    end
  end
end
