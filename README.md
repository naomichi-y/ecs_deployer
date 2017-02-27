# EcsDeployer

This package provides the service deployment function of ECS.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ecs_deployer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ecs_deployer

## Usage

```
ecs_deployer = EcsDeployer::Client.new('cluster_name')
ecs_deployer.register_task('development.yml')
ecs_deployer.update_service('application')
```
