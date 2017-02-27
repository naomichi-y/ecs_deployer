require "spec_helper"

module EcsDeploy
  describe Client do
    describe 'initialize' do
      it 'should be return instance' do
        expect(EcsDeploy::Client.new('test')).to be_a(EcsDeploy::Client)
      end
    end
  end
end
