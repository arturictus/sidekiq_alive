require 'rack/test'
require 'net/http'
RSpec.describe SidekiqAlive::Server do
  include Rack::Test::Methods

  subject(:app) { described_class }

  describe 'responses' do
    it "responds with success when the service is alive" do
      allow(SidekiqAlive).to receive(:alive?) { true }
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('Alive!')
    end

    it "responds with an error when the service is not alive" do
      allow(SidekiqAlive).to receive(:alive?) { false }
      get '/'
      expect(last_response).not_to be_ok
      expect(last_response.body).to eq("Can't find the alive key")
    end
  end
end
