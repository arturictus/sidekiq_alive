require 'rack/test'
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

  describe '.start' do
    it 'logs the setup and then stores the alive key before supering' do
      expect(Sidekiq::Logging.logger).to receive(:info).with(match(/Writing SidekiqAlive alive key in redis:/))
      expect(SidekiqAlive).to receive(:store_alive_key)
      expect(Thread).to receive(:start).and_yield
      expect(described_class).to receive(:run!)

      described_class.start
    end
  end
end
