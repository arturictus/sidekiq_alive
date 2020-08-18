# frozen_string_literal: true

require 'rack/test'
require 'net/http'
RSpec.describe SidekiqAlive::Server do
  include Rack::Test::Methods

  subject(:app) { described_class }

  describe 'responses' do
    it 'responds with success when the service is alive' do
      allow(SidekiqAlive).to receive(:alive?) { true }
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('Alive!')
    end

    it 'responds with an error when the service is not alive' do
      allow(SidekiqAlive).to receive(:alive?) { false }
      get '/'
      expect(last_response).not_to be_ok
      expect(last_response.body).to eq("Can't find the alive key")
    end

    it 'responds not found on an unknown path' do
      get '/unknown-path'
      expect(last_response).not_to be_ok
      expect(last_response.body).to eq("Not found")
    end
  end

  describe 'SidekiqAlive setup port' do
    before do
      ENV['SIDEKIQ_ALIVE_PORT'] = '4567'
      SidekiqAlive.config.set_defaults
    end

    after do
      ENV['SIDEKIQ_ALIVE_PORT'] = nil
    end

    it 'respects the SIDEKIQ_ALIVE_PORT environment variable' do
      expect(described_class.port).to eq '4567'
      expect(described_class.server).to eq 'webrick'
    end
  end

  describe 'SidekiqAlive setup server' do
    before do
      ENV['SIDEKIQ_ALIVE_SERVER'] = 'puma'
      SidekiqAlive.config.set_defaults
    end

    after do
      ENV['SIDEKIQ_ALIVE_SERVER'] = nil
    end

    it 'respects the SIDEKIQ_ALIVE_PORT environment variable' do
      expect(described_class.server).to eq 'puma'
    end
  end

  describe 'SidekiqAlive setup path' do
    before do
      ENV['SIDEKIQ_ALIVE_PATH'] = '/sidekiq-probe'
      SidekiqAlive.config.set_defaults
    end

    after do
      ENV['SIDEKIQ_ALIVE_PATH'] = nil
    end

    it 'respects the SIDEKIQ_ALIVE_PORT environment variable' do
      expect(described_class.path).to eq '/sidekiq-probe'
    end

    it 'responds ok to the given path' do
      allow(SidekiqAlive).to receive(:alive?) { true }
      get '/sidekiq-probe'
      expect(last_response).to be_ok
    end
  end
end
