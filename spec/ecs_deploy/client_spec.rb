require "spec_helper"

module EcsDeployer
  describe Client do
    let(:deployer) { EcsDeployer::Client.new }

    describe 'initialize' do
      it 'should be return instance' do
        expect(deployer).to be_a(EcsDeployer::Client)
        expect(deployer.cli).to be_a(Aws::ECS::Client)
      end
    end

    describe 'register_task' do
      let(:path) { File.expand_path('../fixtures/task.yml', File.dirname(__FILE__)) }

      context 'when success' do
        it 'should be return new task' do
          allow(deployer).to receive(:register_task_hash).and_return('new task')
          expect(deployer.register_task(path)).to eq('new task')
        end
      end

      context 'when file does not exist' do
        it 'should be raise error' do
          allow(File).to receive(:exist?).and_return(false)
          expect{ deployer.register_task(path) }.to raise_error(IOError)
        end
      end
    end
  end
end
