# frozen_string_literal: true

require "rack/test"

ENV["RACK_ENV"] = "test"

RSpec.describe(SidekiqAlive::Server::Rack) do
  include Rack::Test::Methods

  subject(:app) { described_class }

  before do
    described_class.instance_variable_set(:@quiet, nil)
  end

  context "with default configuration" do
    it "responds with success when the service is alive" do
      allow(SidekiqAlive).to(receive(:alive?) { true })

      get "/"
      expect(last_response).to(be_ok)
      expect(last_response.body).to(eq("Alive!"))
    end

    it "responds with an error when the service is not alive" do
      allow(SidekiqAlive).to(receive(:alive?) { false })

      get "/"
      expect(last_response).not_to(be_ok)
      expect(last_response.body).to(eq("Can't find the alive key"))
    end

    it "responds not found on an unknown path" do
      get "/unknown-path"
      expect(last_response).not_to(be_ok)
      expect(last_response.body).to(eq("Not found"))
    end
  end

  context "with custom path" do
    let(:path) { "/sidekiq-probe" }

    before do
      ENV["SIDEKIQ_ALIVE_PATH"] = path
      SidekiqAlive.config.set_defaults
    end

    after do
      ENV["SIDEKIQ_ALIVE_PATH"] = nil
    end

    it "responds ok to the given path" do
      allow(SidekiqAlive).to(receive(:alive?) { true })

      get "/sidekiq-probe"
      expect(last_response).to(be_ok)
    end
  end

  context "with quiet mode" do
    before do
      described_class.instance_variable_set(:@quiet, Time.now)
    end

    it "responds with success and server is shutting down message" do
      get "/"
      expect(last_response).to(be_ok)
      expect(last_response.body).to(eq("Server is shutting down"))
    end
  end
end
