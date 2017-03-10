# EcsDeployer

This package provides service deployment function of ECS.

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
This sample file is in `example/fixtures/task.yml`.

```
container_definitions:
- name: wordpress
  links:
  - mysql
  image: wordpress
  essential: true
  port_mappings:
  - container_port: 80
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

### Encrypt of environment variables

'environment' parameter supports KMS encrypted values.
Encrypted values must be enclosed in '${XXX}'.

```
- environment:
  - name: MYSQL_ROOT_PASSWORD
    value: ${fiSAIfIFxd...}
```

Values are decrypted when task is created.

## Usage

```
ecs_deployer = EcsDeployer::Client.new
ecs_deployer.register_task('development.yml')
ecs_deployer.update_service('cluster', 'development')
```
