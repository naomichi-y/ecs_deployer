require 'spec_helper'

module EcsDeployer
  describe CLI do
    let(:cli) { EcsDeployer::CLI.new }
    let(:deployer_mock) { double('EcsDeployer::Client') }

    before do
      allow(EcsDeployer::Client).to receive(:new).and_return(deployer_mock)
    end

    describe 'prepare' do
      it 'shuld be return EcsDeployer::Client' do
        cli.prepare
        expect(cli.instance_variable_get(:@deployer)).to be_a(RSpec::Mocks::Double)
      end
    end

    describe 'task_register' do
      it 'shuld be output ARN' do
        allow(deployer_mock).to receive(:register_task).and_return('new_task_definition_arn')
        cli.instance_variable_set(:@eployer, deployer_mock)

        options = { path: 'path' }
        expect { cli.invoke(:task_register, [], options) }.to output(/new_task_definition_arn/).to_stdout
      end
    end

    describe 'update_service' do
      it 'shuld be output ARN' do
        allow(deployer_mock).to receive(:update_service).and_return('service_arn')
        allow(deployer_mock).to receive(:timeout=)
        cli.instance_variable_set(:@eployer, deployer_mock)

        options = { cluster: 'cluseter', service: 'service' }
        expect { cli.invoke(:update_service, [], options) }.to output(/service_arn/).to_stdout
      end
    end
  end
end
