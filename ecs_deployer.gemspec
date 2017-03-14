# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ecs_deployer/version'

Gem::Specification.new do |spec|
  spec.name          = "ecs_deployer"
  spec.version       = EcsDeployer::VERSION
  spec.authors       = ["naomichi-y"]
  spec.email         = ["n.yamakita@gmail.com"]

  spec.summary       = %q{Deploy application to ECS.}
  spec.description   = %q{This package provides the service deployment function of ECS.}
  spec.homepage      = "https://github.com/naomichi-y/ecs_deployer"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = ""
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "runtime_command"
  spec.add_dependency "oj"
  spec.add_dependency "thor"
  spec.add_dependency "aws-sdk"
  spec.add_dependency "aws_config"
  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "json_spec"
end
