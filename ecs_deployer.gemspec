# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ecs_deployer/version'

Gem::Specification.new do |spec|
  spec.name          = 'ecs_deployer'
  spec.version       = EcsDeployer::VERSION
  spec.authors       = ['naomichi-y']
  spec.email         = ['n.yamakita@gmail.com']

  spec.summary       = 'Deploy application to ECS.'
  spec.description   = 'Deploy Docker container on AWS ECS.'
  spec.homepage      = 'https://github.com/naomichi-y/ecs_deployer'
  spec.licenses      = ['MIT']

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = ''
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'runtime_command', '~> 1.0'
  spec.add_dependency 'oj', '~> 3.0'
  spec.add_dependency 'thor', '~> 0.19'
  spec.add_dependency 'aws-sdk', '~> 2.9'
  spec.add_dependency 'aws_config', '~> 0.1'
  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'json_spec', '~> 1.1'
  spec.add_development_dependency 'rubocop', '~> 0.48'
  spec.add_development_dependency 'simplecov', '~> 0.14'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 1.0'
end
