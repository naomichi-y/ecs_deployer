require 'spec_helper'

module EcsDeployer
  describe CLI do
    let(:cli) { EcsDeployer::CLI.new }
    let(:deployer_mock) { double('EcsDeployer::Client') }

    before do
      allow(EcsDeployer::Client).to receive(:new).and_return(deployer_mock)
    end

    describe 'prepare' do
      it 'shuld be return EcsDeployer::Client' do
        cli.prepare
        expect(cli.instance_variable_get(:@deployer)).to be_a(RSpec::Mocks::Double)
      end
    end
  end
end
