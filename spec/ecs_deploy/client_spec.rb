require 'spec_helper'

module EcsDeployer
  describe Client do
    let(:deployer) { EcsDeployer::Client.new('cluster') }
    let(:task_definition) { YAML.load(File.read('spec/fixtures/rspec.yml')) }
    let(:environments) do
      [
        {
          name: 'NUMERIC_VALUE',
          value: 0
        },
        {
          name: 'STRING_VALUE',
          value: 'STRING'
        },
        {
          name: 'ENCRYPTED_VALUE',
          value: '${ENCRYPTED_VALUE}'
        }
      ]
    end
    let(:task_definition_with_encrypt) do
      task_definition['container_definitions'][0]['environment'] += environments
      task_definition
    end
    let(:ecs_mock) { double('Aws::ECS::Client') }
    let(:kms_mock) { double('Aws::KMS::Client') }

    before do
      allow(Aws::ECS::Client).to receive(:new).and_return(ecs_mock)
      allow(Aws::KMS::Client).to receive(:new).and_return(kms_mock)
    end

    describe 'initialize' do
      it 'should be return instance' do
        expect(deployer).to be_a(EcsDeployer::Client)
      end

      it 'should be return Aws::ECS::Client' do
        expect(deployer.ecs).to be_a(RSpec::Mocks::Double)
        expect(deployer.wait_timeout).to eq(900)
        expect(deployer.polling_interval).to eq(20)
      end
    end

    describe 'encrypt' do
      context 'when valid master key' do
        let(:encrypt_response) { Aws::KMS::Types::EncryptResponse.new(ciphertext_blob: 'encrypted_value') }

        it 'should be return encrypted value' do
          allow(kms_mock).to receive(:encrypt).and_return(encrypt_response)
          expect(deployer.encrypt('master_key', 'xxx')).to eq('${ZW5jcnlwdGVkX3ZhbHVl}')
        end
      end

      context 'when invalid master key' do
        it 'should be return error' do
          allow(kms_mock).to receive(:encrypt).and_raise(RuntimeError)
          expect { deployer.encrypt('master_key', 'xxx') }.to raise_error(KmsEncryptError)
        end
      end
    end

    describe 'decrypt' do
      context 'when valid encrypted value' do
        let(:decrypt_response) { Aws::KMS::Types::DecryptResponse.new(plaintext: 'decrypted_value') }

        it 'should be return encrypted value' do
          allow(Base64).to receive(:strict_decode64)
          allow(kms_mock).to receive(:decrypt).and_return(decrypt_response)
          expect(deployer.decrypt('${xxx}')).to eq('decrypted_value')
        end
      end

      context 'when invalid encrypted value' do
        context 'when valid value format' do
          it 'should be return error' do
            allow(kms_mock).to receive(:decrypt).and_raise(RuntimeError)
            expect { deployer.decrypt('${xxx}') }.to raise_error(KmsDecryptError)
          end
        end

        context 'when invalid value format' do
          it 'should be return error' do
            expect { deployer.decrypt('xxx') }.to raise_error(KmsDecryptError)
          end
        end
      end
    end

    describe 'register_task' do
      let(:path) { File.expand_path('../fixtures/task.yml', File.dirname(__FILE__)) }

      context 'when success' do
        it 'should be return new task' do
          allow(deployer).to receive(:register_task_hash).and_return(task_definition)
          expect(deployer.register_task(path)).to be_a(Hash)
        end
      end

      context 'when file does not exist' do
        it 'shuld be return error' do
          allow(File).to receive(:exist?).and_return(false)
          expect { deployer.register_task(path) }.to raise_error(IOError)
        end
      end
    end

    describe 'register_task_hash' do
      it 'should be registered task definition' do
        task_definition_mock = double('AWS::ECS::TaskDefinition')
        register_task_definition_response_mock = double('Aws::ECS::Types::RegisterTaskDefinitionResponse')
        allow(register_task_definition_response_mock).to receive(:[]).with(:task_definition).and_return(task_definition_mock)
        allow(deployer.ecs).to receive(:register_task_definition).and_return(register_task_definition_response_mock)

        expect(deployer.register_task_hash(task_definition)).to be_a(task_definition_mock.class)
      end
    end

    describe 'register_clone_task' do
      before do
        allow(deployer.ecs).to receive(:describe_services).and_return(
          services: [
            service_name: 'service'
          ]
        )
        allow(deployer.ecs).to receive(:describe_task_definition).and_return(
          task_definition: {}
        )
        allow(deployer).to receive(:register_task_hash).and_return('new_task_definition_arn')
      end

      context 'when find service' do
        it 'should be return new task definition arn' do
          expect(deployer.register_clone_task('service')).to eq('new_task_definition_arn')
        end
      end

      context 'when not find service' do
        it 'should be return error' do
          expect { deployer.register_clone_task('undefined') }.to raise_error(ServiceNotFoundError)
        end
      end
    end

    describe 'update_service' do
      before do
        allow(deployer.ecs).to receive(:update_service).and_return(
          Aws::ECS::Types::UpdateServiceResponse.new(
            service: Aws::ECS::Types::Service.new(
              service_arn: 'service_arn'
            )
          )
        )
        allow(deployer).to receive(:wait_for_deploy)
      end

      context 'when wait is true' do
        it 'should be return service arn' do
          task_definition_mock = double('AWS::ECS::TaskDefinition')
          allow(task_definition_mock).to receive(:[]).with(:family).and_return('family')
          allow(task_definition_mock).to receive(:[]).with(:revision).and_return('revision')

          expect(deployer.update_service('service', task_definition_mock, true)).to eq('service_arn')
          expect(deployer).to have_received(:wait_for_deploy)
        end
      end

      context 'when wait is false' do
        it 'should be return service arn' do
          task_definition_mock = double('AWS::ECS::TaskDefinition')
          allow(task_definition_mock).to receive(:[]).with(:family).and_return('family')
          allow(task_definition_mock).to receive(:[]).with(:revision).and_return('revision')

          expect(deployer.update_service('service', task_definition_mock, false)).to eq('service_arn')
          expect(deployer).to_not have_received(:wait_for_deploy)
        end
      end
    end

    describe 'decrypt_environment_variables!' do
      context 'when valid task definition' do
        context 'when exist environment parameter' do
          let(:task_definition_hash) { Oj.load(Oj.dump(task_definition_with_encrypt), symbol_keys: true) }
          let(:task_definition_hash_clone) { Marshal.load(Marshal.dump(task_definition_hash)) }
          let(:decrypt_response) { Aws::KMS::Types::DecryptResponse.new(plaintext: 'decrypted_value') }

          before do
            allow(Base64).to receive(:strict_decode64)
            allow(kms_mock).to receive(:decrypt).and_return(decrypt_response)
            deployer.send(:decrypt_environment_variables!, task_definition_hash_clone)
          end

          it 'shuld be return numeric value' do
            expect(task_definition_hash_clone.to_json)
              .to be_json_eql('NUMERIC_VALUE'.to_json).at_path('container_definitions/0/environment/1/name')
            expect(task_definition_hash_clone.to_json)
              .to be_json_eql('0'.to_json).at_path('container_definitions/0/environment/1/value')
          end

          it 'shuld be return string value' do
            expect(task_definition_hash_clone.to_json)
              .to be_json_eql('STRING_VALUE'.to_json).at_path('container_definitions/0/environment/2/name')
            expect(task_definition_hash_clone.to_json)
              .to be_json_eql('STRING'.to_json).at_path('container_definitions/0/environment/2/value')
          end

          it 'shuld be return decrypted values' do
            expect(task_definition_hash_clone.to_json)
              .to be_json_eql('ENCRYPTED_VALUE'.to_json).at_path('container_definitions/0/environment/3/name')
            expect(task_definition_hash_clone.to_json)
              .to be_json_eql('decrypted_value'.to_json).at_path('container_definitions/0/environment/3/value')
          end
        end

        context 'when not exist environment parameter' do
          let(:task_definition_hash) { Oj.load(Oj.dump(task_definition), symbol_keys: true) }
          let(:task_definition_hash_clone) { task_definition_hash.clone }

          it 'should be return json' do
            deployer.send(:decrypt_environment_variables!, task_definition_hash_clone)
            expect(task_definition_hash_clone).to eq(task_definition_hash)
          end
        end
      end

      context 'when invalid task definition' do
        it 'shuld be return error' do
          expect { deployer.send(:decrypt_environment_variables!, {}) }.to raise_error(TaskDefinitionValidateError)
        end
      end
    end

    describe 'exist_service?' do
      before do
        allow(deployer.ecs).to receive(:describe_services).and_return(
          Aws::ECS::Types::DescribeServicesResponse.new(
            services: [Aws::ECS::Types::Service.new(service_name: 'service_name')]
          )
        )
      end

      context 'when exist service' do
        it 'should be return Aws::ECS::Types::Service' do
          expect(deployer.send(:exist_service?, 'service_name')).to be(true)
        end
      end

      context 'when not exist service' do
        it 'should be return false' do
          expect(deployer.send(:exist_service?, 'undefined')).to eq(false)
        end
      end
    end

    describe 'deploy_status' do
      context 'when task exist' do
        context 'when deploying' do
          it 'should be return result' do
            allow(deployer).to receive(:detect_stopped_task)
            allow(deployer.ecs).to receive(:list_tasks).and_return(
              Aws::ECS::Types::ListTasksResponse.new(
                task_arns: ['task_arn']
              )
            )
            allow(deployer.ecs).to receive(:describe_tasks).and_return(
              Aws::ECS::Types::DescribeTasksResponse.new(
                tasks: [
                  Aws::ECS::Types::Task.new(
                    task_definition_arn: 'new_arn',
                    last_status: 'RUNNING'
                  )
                ]
              )
            )
            result = deployer.send(:deploy_status, 'service', 'task_definition_arn')
            expect(result[:current_running_count]).to eq(1)
            expect(result[:new_running_count]).to eq(0)
            expect(result[:task_status_logs][0]).to include('[RUNNING]')
          end
        end

        context 'when deployed' do
          it 'should be return result' do
            allow(deployer).to receive(:detect_stopped_task)
            allow(deployer.ecs).to receive(:list_tasks).and_return(
              Aws::ECS::Types::ListTasksResponse.new(
                task_arns: ['task_arn']
              )
            )
            allow(deployer.ecs).to receive(:describe_tasks).and_return(
              Aws::ECS::Types::DescribeTasksResponse.new(
                tasks: [
                  Aws::ECS::Types::Task.new(
                    task_definition_arn: 'new_arn',
                    last_status: 'RUNNING'
                  ),
                  Aws::ECS::Types::Task.new(
                    task_definition_arn: 'new_arn',
                    last_status: 'RUNNING'
                  )
                ]
              )
            )
            result = deployer.send(:deploy_status, 'service', 'new_arn')
            expect(result[:current_running_count]).to eq(2)
            expect(result[:new_running_count]).to eq(2)
            expect(result[:task_status_logs][0]).to include('[RUNNING]')
          end
        end
      end

      context 'when task not exist' do
        it 'shuld be return error' do
          allow(deployer.ecs).to receive(:list_tasks).and_return(
            Aws::ECS::Types::ListTasksResponse.new(
              task_arns: []
            )
          )
          expect { deployer.send(:deploy_status, 'service', 'task_definition_arn') }.to raise_error(TaskRunningError)
        end
      end
    end

    describe 'wait_for_deploy' do
      context 'when desired count more than 1' do
        context 'when not timed out' do
          it 'should be break' do
            # @TODO
          end
        end

        context 'when timed out' do
          it 'shuld be return error' do
            allow_any_instance_of(EcsDeployer::Client).to receive(:exist_service?).and_return(true)
            allow_any_instance_of(EcsDeployer::Client).to receive(:deploy_status).and_return(
              new_running_count: 0,
              current_running_count: 1,
              task_status_logs: ['task_status_logs']
            )
            deployer.instance_variable_set(:@wait_timeout, 0.03)
            deployer.instance_variable_set(:@polling_interval, 0.01)

            expect { deployer.send(:wait_for_deploy, 'service', 'task_definition_arn') }.to raise_error(DeployTimeoutError)
          end
        end
      end
    end
  end
end
