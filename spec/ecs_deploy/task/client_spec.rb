require 'spec_helper'

module EcsDeployer
  module Task
    describe Client do
      let(:task_client) { EcsDeployer::Task::Client.new('cluster', region: 'ap-northeast-1') }
      let(:task_definition) { YAML.load(File.read('spec/fixtures/rspec.yml')) }
      let(:kms_client_mock) { double('Aws::KMS::Client') }
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
      let(:ecs_client_mock) { double('Aws::ECS::Client') }

      before do
        allow(Aws::KMS::Client).to receive(:new).and_return(kms_client_mock)
      end

      describe 'register' do
        let(:path) { File.expand_path('../../fixtures/task.yml', File.dirname(__FILE__)) }

        context 'when success' do
          it 'should be return new task' do
            allow(task_client).to receive(:register_hash).and_return(task_definition)
            expect(task_client.register(path)).to be_a(Hash)
          end
        end

        context 'when file does not exist' do
          it 'shuld be return error' do
            allow(File).to receive(:exist?).and_return(false)
            expect { task_client.register(path) }.to raise_error(IOError)
          end
        end
      end

      describe 'register_hash' do
        it 'should be registered task definition' do
          task_definition_mock = double('AWS::ECS::TaskDefinition')
          register_task_definition_response_mock = double('Aws::ECS::Types::RegisterTaskDefinitionResponse')
          allow(register_task_definition_response_mock).to receive(:[]).with(:task_definition).and_return(task_definition_mock)
          allow(ecs_client_mock).to receive(:register_task_definition).and_return(register_task_definition_response_mock)
          allow(Aws::ECS::Client).to receive(:new).and_return(ecs_client_mock)

          expect(task_client.register_hash(task_definition)).to be_a(task_definition_mock.class)
        end
      end

      describe 'register_clone' do
        before do
          allow(Aws::ECS::Client).to receive(:new).and_return(ecs_client_mock)
          allow(ecs_client_mock).to receive(:describe_services).and_return(
            services: [
              service_name: 'service'
            ]
          )
          allow(ecs_client_mock).to receive(:describe_task_definition).and_return(
            task_definition: {}
          )
          allow(task_client).to receive(:register_hash).and_return('new_task_definition_arn')
        end

        context 'when find service' do
          it 'should be return new task definition arn' do
            expect(task_client.register_clone('service')).to eq('new_task_definition_arn')
          end
        end

        context 'when not find service' do
          it 'should be return error' do
            expect { task_client.register_clone('undefined') }.to raise_error(ServiceNotFoundError)
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
              allow(kms_client_mock).to receive(:decrypt).and_return(decrypt_response)
              task_client.send(:decrypt_environment_variables!, task_definition_hash_clone)
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
              task_client.send(:decrypt_environment_variables!, task_definition_hash_clone)
              expect(task_definition_hash_clone).to eq(task_definition_hash)
            end
          end
        end

        context 'when invalid task definition' do
          it 'shuld be return error' do
            expect { task_client.send(:decrypt_environment_variables!, {}) }.to raise_error(TaskDefinitionValidateError)
          end
        end
      end
    end
  end
end
