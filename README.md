# EcsDeployer

[![CircleCI](https://circleci.com/gh/naomichi-y/ecs_deployer/tree/master.svg?style=svg)](https://circleci.com/gh/naomichi-y/ecs_deployer/tree/master)
[![Gem Version](https://badge.fury.io/rb/ecs_deployer.svg)](https://badge.fury.io/rb/ecs_deployer)

## Description

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
  memory: 512
  cpu: 10
- environment:
  - name: MYSQL_ROOT_PASSWORD
    value: password
  name: mysql
  image: mysql
  cpu: 10
  memory: 512
  essential: true
family: hello_world
```

### Encrypt of environment variables

`environment` parameter supports KMS encrypted values.
Encrypted values must be enclosed in `${XXX}`.

```
- environment:
  - name: MYSQL_ROOT_PASSWORD
    value: ${fiSAIfIFxd...}
```

Values are decrypted when task is created.

## Usage

### API

This sample file is in `spec/fixtures/task.yml`.

```
deployer = EcsDeployer::Client.new
deployer.register_task('development.yml')
deployer.update_service('cluster', 'development')
```

### CLI

#### Register new task

```
$ bundle exec ecs_deployer task-register --path=example/fixtures/task.yml
```

#### Encrypt environment value

```
$ bundle exec ecs_deployer encrypt --master-key=master --value='test'
Encrypted value: ${xxx}
```

#### Decrypt environment value

```
$ bundle exec ecs_deployer decrypt --value='${xxx}'
Decrypted value: xxx
```

#### Update service

```
$ bundle exec ecs_deployer update-service --cluster=xxx --service=xxx --wait --timeout=600
```
