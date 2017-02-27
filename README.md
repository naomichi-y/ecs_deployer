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

## Task definition

Write task definition in YAML format.
For available parameters see [Task Definition Parameters](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html).
The sample file is in `example/fixtures/task.yml`.

```
containerDefinitions:
- name: wordpress
  links:
  - mysql
  image: wordpress
  essential: true
  portMappings:
  - containerPort: 80
    hostPort: 80
  memory: 500
  cpu: 10
- environment:
  - name: MYSQL_ROOT_PASSWORD
    value: password
  name: mysql
  image: mysql
  cpu: 10
  memory: 500
  essential: true
family: hello_world
```

## Usage

```
ecs_deployer = EcsDeployer::Client.new('cluster_name')
ecs_deployer.register_task('development.yml')
ecs_deployer.update_service('application')
```
