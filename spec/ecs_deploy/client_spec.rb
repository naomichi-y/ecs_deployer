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
