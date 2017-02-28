require "spec_helper"

module EcsDeployer
  describe Commander do
    let(:runtime) { RuntimeCommand::Builder.new }
    let(:commander) { EcsDeployer::Commander.new(runtime) }
    let(:logger_mock) { double('logger_mock', buffered_stdout: '{}', buffered_stderr: '') }

    before do
      allow(runtime).to receive(:exec).and_return(logger_mock)
    end

    describe 'initialize' do
      it 'should be return instance' do
        expect(EcsDeployer::Commander.new(runtime)).to be_a(EcsDeployer::Commander)
      end
    end

    describe 'update_service' do
      it 'should be return Hash' do
        expect(commander.update_service('')).to be_a(Hash)
      end
    end

    describe 'list_tasks' do
      it 'should be return Hash' do
        expect(commander.list_tasks({})).to be_a(Hash)
      end
    end

    describe 'describe_tasks' do
      it 'should be return Hash' do
        expect(commander.describe_tasks([])).to be_a(Hash)
      end
    end

    describe 'describe_task_definition' do
      it 'should be return Hash' do
        expect(commander.describe_task_definition('')).to be_a(Hash)
      end
    end

    describe 'describe_services' do
      it 'should be return Hash' do
        expect(commander.describe_services([])).to be_a(Hash)
      end
    end

    describe 'register_task_definition' do
      it 'should be return Hash' do
        expect(commander.list_tasks).to be_a(Hash)
      end
    end
  end
end
