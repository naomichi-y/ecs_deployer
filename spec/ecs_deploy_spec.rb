require "spec_helper"

RSpec.describe EcsDeploy do
  it "has a version number" do
    expect(EcsDeploy::VERSION).not_to be nil
  end
end
