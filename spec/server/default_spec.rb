# frozen_string_literal: true

require "net/http"

RSpec.describe(SidekiqAlive::Server::Default) do
  let(:port) { 7433 }
  let(:path) { "/" }
  let(:server) { SidekiqAlive::Server::Default.new(port, "0.0.0.0", path) }

  before do
    server.start
  end

  after do
    server.stop
  end

  def get(uri)
    @last_response = Net::HTTP.get_response(URI("http://localhost:#{port}#{uri}"))
  end

  context "with default configuration" do
    it "responds with success when the service is alive" do
      allow(SidekiqAlive).to(receive(:alive?) { true })

      get "/"
      expect(@last_response.code).to(eq("200"))
      expect(@last_response.body).to(eq("Alive!"))
    end

    it "responds with an error when the service is not alive" do
      allow(SidekiqAlive).to(receive(:alive?) { false })

      get "/"
      expect(@last_response.code).to(eq("404"))
      expect(@last_response.body).to(eq("Can't find the alive key"))
    end

    it "responds not found on an unknown path" do
      get "/unknown-path"
      expect(@last_response.code).to(eq("404"))
      expect(@last_response.body).to(eq("Not found"))
    end
  end

  context "with custom path" do
    let(:path) { "/sidekiq-probe" }

    it "responds ok to the given path" do
      allow(SidekiqAlive).to(receive(:alive?) { true })

      get "/sidekiq-probe"
      expect(@last_response.code).to(eq("200"))
    end
  end
end
