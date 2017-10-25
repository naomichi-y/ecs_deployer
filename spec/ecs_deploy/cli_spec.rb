require 'spec_helper'

module EcsDeployer
  describe CLI do
    let(:cli) { EcsDeployer::CLI.new }

    describe 'task_register' do
      it 'shuld be output ARN' do
        task_definition_mock = double('Aws::ECS::Types::TaskDefinition')
        task_client_mock = double('EcsDeployer::Task::Client')

        allow(task_client_mock).to receive(:register).and_return(task_definition_mock)
        allow(task_definition_mock).to receive(:task_definition_arn).and_return('new_task_definition_arn')
        allow(EcsDeployer::Task::Client).to receive(:new).and_return(task_client_mock)

        options = { path: 'path' }
        expect { cli.invoke(:task_register, [], options) }.to output(/new_task_definition_arn/).to_stdout
      end
    end

    describe 'update_service' do
      it 'shuld be output ARN' do
        service_client_mock = double('EcsDeployer::Service::Client')
        service_mock = double('Aws::ECS::Types::Service')
        deployer_client_mock = double('EcsDeployer::Client')

        allow(service_client_mock).to receive(:wait_timeout=)
        allow(service_mock).to receive(:service_arn).and_return('service_arn')
        allow(service_client_mock).to receive(:update).and_return(service_mock)
        allow(deployer_client_mock).to receive(:service).and_return(service_client_mock)
        allow(EcsDeployer::Client).to receive(:new).and_return(deployer_client_mock)

        options = { cluster: 'cluseter', service: 'service' }
        expect { cli.invoke(:update_service, [], options) }.to output(/service_arn/).to_stdout
      end
    end
  end
end
