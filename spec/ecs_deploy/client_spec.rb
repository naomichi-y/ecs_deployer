require "spec_helper"

module EcsDeployer
  describe Client do
    describe 'initialize' do
      it 'should be return instance' do
        expect(EcsDeployer::Client.new).to be_a(EcsDeployer::Client)
      end
    end
  end
end
