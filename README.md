# EcsDeploy

This package provides the service deployment function of ECS.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ecs_deploy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ecs_deploy

## Usage

```
ecs_deploy = EcsDeploy::Client.new('cluster_name')
ecs_deploy.register_task('development.yml')
ecs_deploy.update_service('application')
```
