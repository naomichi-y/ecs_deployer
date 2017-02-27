require "spec_helper"

module EcsDeployer
  describe Commander do
    describe 'initialize' do
      it 'should be return instance' do
        expect(EcsDeployer::Commander.new('test')).to be_a(EcsDeployer::Commander)
      end
    end
  end
end
