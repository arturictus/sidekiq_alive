# frozen_string_literal: true

around_config = proc do |example|
  ENV["SIDEKIQ_ALIVE_HOST"] = "1.2.3.4"
  ENV["SIDEKIQ_ALIVE_PORT"] = "4567"
  ENV["SIDEKIQ_ALIVE_PATH"] = "/health"
  SidekiqAlive.config.set_defaults

  example.run

  ENV["SIDEKIQ_ALIVE_HOST"] = nil
  ENV["SIDEKIQ_ALIVE_PORT"] = nil
  ENV["SIDEKIQ_ALIVE_PATH"] = nil
end

RSpec.describe(SidekiqAlive::Server) do
  subject(:app) { described_class }

  context "with default server" do
    let(:fake_server) { instance_double(SidekiqAlive::Server::Default, start: nil, stop: nil) }

    before { allow(SidekiqAlive::Server::Default).to(receive(:new).and_return(fake_server)) }

    context "with default config" do
      it "starts server with default arguments" do
        app.run!

        expect(SidekiqAlive::Server::Default).to(have_received(:new).with(7433, "0.0.0.0", "/"))
        expect(fake_server).to(have_received(:start))
      end

      it "shuts down server" do
        server = app.run!
        server.shutdown!

        expect(fake_server).to(have_received(:stop))
      end
    end

    context "with changed host, port and path configuration" do
      around(&around_config)

      it "starts with updated configuration" do
        app.run!

        expect(SidekiqAlive::Server::Default).to(have_received(:new).with(4567, "1.2.3.4", "/health"))
      end
    end
  end

  context "rack based server" do
    let(:pid) { Random.rand(1000) }
    let(:fake_server) { double("rack server", run: pid, shutdown: nil) }

    before do
      ENV["SIDEKIQ_ALIVE_SERVER"] = "webrick"
      SidekiqAlive.config.set_defaults

      allow(Rack::Handler).to(receive(:get).and_return(fake_server))
      allow(SidekiqAlive::Server::Rack).to(receive(:fork).and_yield)

      allow(Signal).to(receive(:trap))
      allow(Process).to(receive(:kill))
      allow(Process).to(receive(:wait))
    end

    after { ENV["SIDEKIQ_ALIVE_SERVER"] = nil }

    context "with default config" do
      it "starts server with default arguments and captures TERM" do
        app.run!

        expect(Rack::Handler).to(have_received(:get).with("webrick"))
        expect(Signal).to(have_received(:trap).with("TERM")) do |&block|
          block.call

          expect(fake_server).to(have_received(:shutdown))
        end
        expect(fake_server).to(have_received(:run).with(
          SidekiqAlive::Server::Rack, Port: 7433, Host: "0.0.0.0", AccessLog: [], Logger: SidekiqAlive.logger
        ))
      end

      it "shuts down server" do
        server = app.run!
        server.shutdown!

        expect(Process).to(have_received(:kill).with("TERM", pid))
        expect(Process).to(have_received(:wait).with(pid))
      end
    end

    context "with changed host, port and path configuration" do
      around(&around_config)

      it "starts with updated configuration" do
        app.run!

        expect(fake_server).to(have_received(:run).with(
          SidekiqAlive::Server::Rack, Port: 4567, Host: "1.2.3.4", AccessLog: [], Logger: SidekiqAlive.logger
        ))
      end
    end
  end
end
