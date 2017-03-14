require "spec_helper"

module EcsDeployer
  describe Client do
    let(:deployer) { EcsDeployer::Client.new }
    let(:task_definition) { YAML::load(File.read('spec/fixtures/task.yml')) }
    let(:task_definition_with_encrypt) {
      task_definition['container_definitions'][0]['environment'] += [
        'name': 'ENCRYPT_KEY',
        'value': '${ENCRYPT_VALUE}'
      ]
      task_definition
    }

    describe 'initialize' do
      it 'should be return instance' do
        expect(deployer).to be_a(EcsDeployer::Client)
      end

      it 'should be return Aws::ECS::Client' do
        expect(deployer.cli).to be_a(Aws::ECS::Client)
      end
    end

    describe 'encrypt' do
      context 'when valid master key' do
        let(:encrypt_response) { Aws::KMS::Types::EncryptResponse.new(ciphertext_blob: 'encrypted_value') }

        it 'should be return encrypted value' do
          allow_any_instance_of(Aws::KMS::Client).to receive(:encrypt).and_return(encrypt_response)
          expect(deployer.encrypt('master_key', 'xxx')).to eq('${ZW5jcnlwdGVkX3ZhbHVl}')
        end
      end

      context 'when invalid master key' do
        it 'should be return error' do
          allow_any_instance_of(Aws::KMS::Client).to receive(:encrypt).and_raise(RuntimeError)
          expect{ deployer.encrypt('master_key', 'xxx') }.to raise_error(KmsEncryptError)
        end
      end
    end

    describe 'decrypt' do
      context 'when valid encrypted value' do
        let(:decrypt_response) { Aws::KMS::Types::DecryptResponse.new(plaintext: 'decrypted_value') }

        it 'should be return encrypted value' do
          allow(Base64).to receive(:strict_decode64)
          allow_any_instance_of(Aws::KMS::Client).to receive(:decrypt).and_return(decrypt_response)
          expect(deployer.decrypt('${xxx}')).to eq('decrypted_value')
        end
      end

      context 'when invalid encrypted value' do
        context 'when valid value format' do
          it 'should be return error' do
            allow_any_instance_of(Aws::KMS::Client).to receive(:decrypt).and_raise(RuntimeError)
            expect{ deployer.decrypt('${xxx}') }.to raise_error(KmsDecryptError)
          end
        end

        context 'when invalid value format' do
          it 'should be return error' do
            expect{ deployer.decrypt('xxx') }.to raise_error(KmsDecryptError)
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
          expect{ deployer.register_task(path) }.to raise_error(IOError)
        end
      end
    end

    describe 'register_task_hash' do
      it 'should be registered task definition' do
        allow(deployer.cli).to receive(:register_task_definition).and_return({
          task_definition: {
            family: 'family',
            revision: 'revision',
            task_definition_arn: 'new_task_definition_arn'
          }
        })

        expect(deployer.register_task_hash(task_definition)).to eq('new_task_definition_arn')
        expect(deployer.instance_variable_get(:@family)).to eq('family')
        expect(deployer.instance_variable_get(:@revision)).to eq('revision')
        expect(deployer.instance_variable_get(:@new_task_definition_arn)).to eq('new_task_definition_arn')
      end
    end

    describe 'register_clone_task' do
      before do
        allow(deployer.cli).to receive(:describe_services).and_return({
          services: [
            service_name: 'service'
          ]
        })
        allow(deployer.cli).to receive(:describe_task_definition).and_return({
          task_definition: {}
        })
        allow(deployer).to receive(:register_task_hash).and_return('new_task_definition_arn')
      end

      context 'when find service' do
        it 'should be return new task definition arn' do
          expect(deployer.register_clone_task('cluster', 'service')).to eq('new_task_definition_arn')
        end
      end

      context 'when not find service' do
        it 'should be return error' do
          expect{ deployer.register_clone_task('cluster', 'undefined') }.to raise_error(ServiceNotFoundError)
        end
      end
    end

    describe 'decrypt_environment_variables!' do
      context 'when valid task definition' do
        context 'when exist environment parameter' do
          let(:task_definition_hash) { Oj.load(Oj.dump(task_definition_with_encrypt), symbol_keys: true) }
          let(:task_definition_hash_clone) { Marshal.load(Marshal.dump(task_definition_hash)) }
          let(:decrypt_response) { Aws::KMS::Types::DecryptResponse.new(plaintext: 'decrypted_value') }

          it 'shuld be return decrypted values' do
            allow(Base64).to receive(:strict_decode64)
            allow_any_instance_of(Aws::KMS::Client).to receive(:decrypt).and_return(decrypt_response)

            deployer.send(:decrypt_environment_variables!, task_definition_hash_clone)
            expect(task_definition_hash_clone.to_json)
              .to be_json_eql('ENCRYPT_KEY'.to_json).at_path('container_definitions/0/environment/1/name')
            expect(task_definition_hash_clone.to_json)
              .to be_json_eql('decrypted_value'.to_json).at_path('container_definitions/0/environment/1/value')
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
          expect{ deployer.send(:decrypt_environment_variables!, {}) }.to raise_error(TaskDefinitionValidateError)
        end
      end
    end
  end
end
