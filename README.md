# EcsDeployer

[![Gem Version](https://badge.fury.io/rb/ecs_deployer.svg)](https://badge.fury.io/rb/ecs_deployer)
[![Test Coverage](https://codeclimate.com/github/naomichi-y/ecs_deployer/badges/coverage.svg)](https://codeclimate.com/github/naomichi-y/ecs_deployer/coverage)
[![Code Climate](https://codeclimate.com/github/naomichi-y/ecs_deployer/badges/gpa.svg)](https://codeclimate.com/github/naomichi-y/ecs_deployer)
[![CircleCI](https://circleci.com/gh/naomichi-y/ecs_deployer/tree/master.svg?style=svg)](https://circleci.com/gh/naomichi-y/ecs_deployer/tree/master)

## Description

This package provides service deployment function of ECS.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ecs_deployer'
```

And then execute:

```ruby
$ bundle
```

Or install it yourself as:

```ruby
$ gem install ecs_deployer
```

## Task definition

Write task definition in YAML format.
For available parameters see [Task Definition Parameters](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html).

```yaml
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

```yaml
- environment:
  - name: MYSQL_ROOT_PASSWORD
    value: ${fiSAIfIFxd...}
```

Values are decrypted when task is created.

## Usage

### API

This sample file is in `spec/fixtures/task.yml`.

```ruby
deployer = EcsDeployer::Client.new
deployer.register_task('development.yml')
deployer.update_service('cluster', 'development')
```

`{{xxx}}` parameter is construed variable.

```yaml
container_definitions:
- name: wordpress
  image: wordpress:{{tag}}
```

```ruby
deployer.register_task('development.yml', tag: 'latest')
```

### CLI

#### Register new task

```ruby
$ bundle exec ecs_deployer task-register --path=example/fixtures/task.yml
```

#### Encrypt environment value

```ruby
$ bundle exec ecs_deployer encrypt --master-key=master --value='test'
Encrypted value: ${xxx}
```

#### Decrypt environment value

```ruby
$ bundle exec ecs_deployer decrypt --value='${xxx}'
Decrypted value: xxx
```

#### Update service

```ruby
$ bundle exec ecs_deployer update-service --cluster=xxx --service=xxx --wait --timeout=600
```
