require 'spec_helper'

module EcsDeployer
  describe Client do
    let(:client) { EcsDeployer::Client.new('cluster') }

    describe 'initialize' do
      it 'should be reeturn EcsDeployer::Client' do
        expect(client).to be_a(EcsDeployer::Client)
      end
    end

    describe 'task' do
      it 'should be return EcsDeployer::Task::Client' do
        task_client_mock = double('EcsDeployer::Task::Client')
        allow(EcsDeployer::Task::Client).to receive(:new).and_return(task_client_mock)
        expect(client.task).to be_a(task_client_mock.class)
      end
    end

    describe 'scheduled_task' do
      it 'should be return EcsDeployer::ScheduledTask::Client' do
        scheduled_task_client_mock= double('EcsDeployer::ScheduledTask::Client')
        allow(EcsDeployer::ScheduledTask::Client).to receive(:new).and_return(scheduled_task_client_mock)
        expect(client.scheduled_task).to be_a(scheduled_task_client_mock.class)
      end
    end

    describe 'service' do
      it 'should be return EcsDeployer::Service::Client' do
        service_client_mock= double('EcsDeployer::Service::Client')
        allow(EcsDeployer::Service::Client).to receive(:new).and_return(service_client_mock)
        expect(client.service).to be_a(service_client_mock.class)
      end
    end
  end
end
