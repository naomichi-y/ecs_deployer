require 'spec_helper'

module EcsDeployer
  describe Client do
    let(:client) { EcsDeployer::ScheduledTask::Client.new('cluster') }
    let(:cloud_watch_events_mock) { double('Aws::CloudWatchEvents::Client') }

    before do
      allow(Aws::CloudWatchEvents::Client).to receive(:new).and_return(cloud_watch_events_mock)
    end

    describe 'exist_rule?' do
      context 'when rule exist' do
        it 'shuold be return true' do
          allow(cloud_watch_events_mock).to receive(:describe_rule).and_return(true)
          expect(client.exist_rule?('rule')).to eq(true)
        end
      end

      context 'when rule does not exist' do
        it 'shuold be return false' do
          context_mock = double('Seahorse::Client::RequestContext')
          allow(cloud_watch_events_mock).to receive(:describe_rule).and_raise(Aws::CloudWatchEvents::Errors::ResourceNotFoundException.new(context_mock, 'error'))
          expect(client.exist_rule?('rule')).to eq(false)
        end
      end
    end

    describe 'target_builder' do
      it 'shuold be return EcsDeployer::ScheduledTask::Client' do
        target_mock = double('EcsDeployer::ScheduledTask::Target')
        allow(EcsDeployer::ScheduledTask::Target).to receive(:new).and_return(target_mock)

        expect(client.target_builder('id')).to be_a(target_mock.class)
      end
    end
  end
end
