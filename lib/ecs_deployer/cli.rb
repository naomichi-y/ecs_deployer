require 'thor'

module EcsDeployer
  class CLI < Thor
    desc 'hello', 'world'
    def update
      puts 'hello'
    end
  end
end
