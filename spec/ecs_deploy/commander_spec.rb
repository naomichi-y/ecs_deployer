require "spec_helper"

module EcsDeploy
  describe Commander do
    describe 'initialize' do
      it 'should be return instance' do
        expect(EcsDeploy::Commander.new('test')).to be_a(EcsDeploy::Commander)
      end
    end
  end
end
