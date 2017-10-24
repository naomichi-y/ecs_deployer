require 'spec_helper'

module EcsDeployer
  describe Client do
    let(:deployer) { EcsDeployer::Client.new('cluster', nil, region: 'ap-northeast-1') }
    let(:task_definition) { YAML.load(File.read('spec/fixtures/rspec.yml')) }
    let(:ecs_mock) { double('Aws::ECS::Client') }

    before do
      allow(Aws::ECS::Client).to receive(:new).and_return(ecs_mock)
    end

    describe 'update_service' do
      before do
        allow(deployer.ecs).to receive(:update_service).and_return(
          Aws::ECS::Types::UpdateServiceResponse.new(
            service: Aws::ECS::Types::Service.new(
              service_arn: 'service_arn'
            )
          )
        )
        allow(deployer).to receive(:wait_for_deploy)
      end

      context 'when wait is true' do
        it 'should be return service arn' do
          task_definition_mock = double('AWS::ECS::TaskDefinition')
          allow(task_definition_mock).to receive(:[]).with(:family).and_return('family')
          allow(task_definition_mock).to receive(:[]).with(:revision).and_return('revision')

          expect(deployer.update_service('service', task_definition_mock, true)).to eq('service_arn')
          expect(deployer).to have_received(:wait_for_deploy)
        end
      end

      context 'when wait is false' do
        it 'should be return service arn' do
          task_definition_mock = double('AWS::ECS::TaskDefinition')
          allow(task_definition_mock).to receive(:[]).with(:family).and_return('family')
          allow(task_definition_mock).to receive(:[]).with(:revision).and_return('revision')

          expect(deployer.update_service('service', task_definition_mock, false)).to eq('service_arn')
          expect(deployer).to_not have_received(:wait_for_deploy)
        end
      end
    end

    describe 'exist_service?' do
      before do
        allow(deployer.ecs).to receive(:describe_services).and_return(
          Aws::ECS::Types::DescribeServicesResponse.new(
            services: [Aws::ECS::Types::Service.new(service_name: 'service_name')]
          )
        )
      end

      context 'when exist service' do
        it 'should be return Aws::ECS::Types::Service' do
          expect(deployer.send(:exist_service?, 'service_name')).to be(true)
        end
      end

      context 'when not exist service' do
        it 'should be return false' do
          expect(deployer.send(:exist_service?, 'undefined')).to eq(false)
        end
      end
    end

    describe 'deploy_status' do
      context 'when task exist' do
        context 'when deploying' do
          it 'should be return result' do
            allow(deployer).to receive(:detect_stopped_task)
            allow(deployer.ecs).to receive(:list_tasks).and_return(
              Aws::ECS::Types::ListTasksResponse.new(
                task_arns: ['task_arn']
              )
            )
            allow(deployer.ecs).to receive(:describe_tasks).and_return(
              Aws::ECS::Types::DescribeTasksResponse.new(
                tasks: [
                  Aws::ECS::Types::Task.new(
                    task_definition_arn: 'new_arn',
                    last_status: 'RUNNING'
                  )
                ]
              )
            )
            result = deployer.send(:deploy_status, 'service', 'task_definition_arn')
            expect(result[:current_running_count]).to eq(1)
            expect(result[:new_running_count]).to eq(0)
            expect(result[:task_status_logs][0]).to include('[RUNNING]')
          end
        end

        context 'when deployed' do
          it 'should be return result' do
            allow(deployer).to receive(:detect_stopped_task)
            allow(deployer.ecs).to receive(:list_tasks).and_return(
              Aws::ECS::Types::ListTasksResponse.new(
                task_arns: ['task_arn']
              )
            )
            allow(deployer.ecs).to receive(:describe_tasks).and_return(
              Aws::ECS::Types::DescribeTasksResponse.new(
                tasks: [
                  Aws::ECS::Types::Task.new(
                    task_definition_arn: 'new_arn',
                    last_status: 'RUNNING'
                  ),
                  Aws::ECS::Types::Task.new(
                    task_definition_arn: 'new_arn',
                    last_status: 'RUNNING'
                  )
                ]
              )
            )
            result = deployer.send(:deploy_status, 'service', 'new_arn')
            expect(result[:current_running_count]).to eq(2)
            expect(result[:new_running_count]).to eq(2)
            expect(result[:task_status_logs][0]).to include('[RUNNING]')
          end
        end
      end

      context 'when task not exist' do
        it 'shuld be return error' do
          allow(deployer.ecs).to receive(:list_tasks).and_return(
            Aws::ECS::Types::ListTasksResponse.new(
              task_arns: []
            )
          )
          expect { deployer.send(:deploy_status, 'service', 'task_definition_arn') }.to raise_error(TaskRunningError)
        end
      end
    end

    describe 'wait_for_deploy' do
      context 'when desired count more than 1' do
        context 'when not timed out' do
          it 'should be break' do
            # @TODO
          end
        end

        context 'when timed out' do
          it 'shuld be return error' do
            allow_any_instance_of(EcsDeployer::Client).to receive(:exist_service?).and_return(true)
            allow_any_instance_of(EcsDeployer::Client).to receive(:deploy_status).and_return(
              new_running_count: 0,
              current_running_count: 1,
              task_status_logs: ['task_status_logs']
            )
            deployer.instance_variable_set(:@wait_timeout, 0.03)
            deployer.instance_variable_set(:@polling_interval, 0.01)

            expect { deployer.send(:wait_for_deploy, 'service', 'task_definition_arn') }.to raise_error(DeployTimeoutError)
          end
        end
      end
    end
  end
end
