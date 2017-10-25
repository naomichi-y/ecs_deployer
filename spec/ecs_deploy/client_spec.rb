require 'spec_helper'

module EcsDeployer
  describe Client do
    let(:client) { EcsDeployer::Client.new('cluster', nil, region: 'ap-northeast-1') }

    context 'initialize' do
      it 'should be reeturn EcsDeployer::Client' do
        expect(client).to be_a(EcsDeployer::Client)
      end
    end

    context 'task' do
      it 'should be return EcsDeployer::Task::Client' do
        expect(client.task).to be_a(EcsDeployer::Task::Client)
      end
    end

    context 'scheduled_task' do
      it 'should be return EcsDeployer::ScheduledTask::Client' do
        expect(client.scheduled_task).to be_a(EcsDeployer::ScheduledTask::Client)
      end
    end

    context 'service' do
      it 'should be return EcsDeployer::Service::Client' do
        expect(client.service).to be_a(EcsDeployer::Service::Client)
      end
    end
  end
end
