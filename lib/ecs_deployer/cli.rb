require 'thor'

module EcsDeployer
  class CLI < Thor
    class_option :profile, type: :string
    class_option :region, type: :string

    no_commands do
      def prepare
        aws_options = {}
        aws_options[:profile] = options[:profile] if options[:profile]
        aws_options[:region] = options[:region] if options[:region]

        @deployer = EcsDeployer::Client.new(aws_options)

        nil
      end

      def invoke_command(command, *args)
        prepare
        super
      end
    end

    desc 'task_register', 'Create new task definition'
    option :path, required: true
    option :replace_variables, type: :hash, default: {}
    def task_register
      path = File.expand_path(options[:path], Dir.pwd)
      result = @deployer.register_task(path, options[:replace_variables])

      puts "Registered task: #{result}"
    end

    desc 'update_service', 'Update service difinition.'
    option :cluster, required: true
    option :service, required: true
    option :wait, type: :boolean, default: true
    option :timeout, type: :numeric, default: 600
    def update_service
      @deployer.timeout = options[:timeout]
      result = @deployer.update_service(
        options[:cluster],
        options[:service],
        options[:wait]
      )

      puts "Update service: #{result}"
    end

    desc 'encrypt', 'Encrypt value of argument with KMS.'
    option :master_key, required: true
    option :value, required: true
    def encrypt
      puts "Encrypted value: #{@deployer.encrypt(options[:master_key], options[:value])}"
    end

    desc 'decrypt', 'Decrypt value of argument with KMS.'
    option :value, required: true
    def decrypt
      puts "Decrypted value: #{@deployer.decrypt(options[:value])}"
    end
  end
end
