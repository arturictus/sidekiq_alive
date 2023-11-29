# frozen_string_literal: true

require "net/http"

RSpec.shared_context("with http server") do
  let(:port) { 7433 }
  let(:path) { "/" }
  let(:server) { SidekiqAlive::Server.new(port, "0.0.0.0", path) }

  before { server.start }
  after { server.stop }

  def get(uri)
    @last_response = Net::HTTP.get_response(URI("http://localhost:#{port}#{uri}"))
  end

  attr_reader :last_response
end

RSpec.describe(SidekiqAlive::Server) do
  subject(:app) { described_class }

  describe "#run!" do
    let(:fake_server) { instance_double(SidekiqAlive::Server, start: nil) }

    before { allow(SidekiqAlive::Server).to(receive(:new).and_return(fake_server)) }

    it "starts server with default arguments" do
      app.run!

      expect(SidekiqAlive::Server).to(have_received(:new).with(7433, "0.0.0.0", "/"))
      expect(fake_server).to(have_received(:start))
    end

    context "with changed host, port and path configuration" do
      around do |example|
        ENV["SIDEKIQ_ALIVE_HOST"] = "1.2.3.4"
        ENV["SIDEKIQ_ALIVE_PORT"] = "4567"
        ENV["SIDEKIQ_ALIVE_PATH"] = "/health"
        SidekiqAlive.config.set_defaults

        example.run

        ENV["SIDEKIQ_ALIVE_HOST"] = nil
        ENV["SIDEKIQ_ALIVE_PORT"] = nil
        ENV["SIDEKIQ_ALIVE_PATH"] = nil
      end

      it "respects the SIDEKIQ_ALIVE_HOST environment variable" do
        app.run!

        expect(SidekiqAlive::Server).to(have_received(:new).with(4567, "1.2.3.4", "/health"))
      end
    end
  end

  describe "responses" do
    include_context("with http server")

    context "with default configuration" do
      it "responds with success when the service is alive" do
        allow(SidekiqAlive).to(receive(:alive?) { true })

        get "/"
        expect(last_response.code).to(eq("200"))
        expect(last_response.body).to(eq("Alive!"))
      end

      it "responds with an error when the service is not alive" do
        allow(SidekiqAlive).to(receive(:alive?) { false })

        get "/"
        expect(last_response.code).to(eq("404"))
        expect(last_response.body).to(eq("Can't find the alive key"))
      end

      it "responds not found on an unknown path" do
        get "/unknown-path"
        expect(last_response.code).to(eq("404"))
        expect(last_response.body).to(eq("Not found"))
      end
    end

    context "with custom path" do
      let(:path) { "/sidekiq-probe" }

      it "responds ok to the given path" do
        allow(SidekiqAlive).to(receive(:alive?) { true })

        get "/sidekiq-probe"
        expect(last_response.code).to(eq("200"))
      end
    end
  end
end
