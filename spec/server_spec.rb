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

  let(:pid) { Random.rand(1000) }

  before do
    allow(Process).to(receive(:fork).and_return(pid))
    allow(Process).to(receive(:kill))
    allow(Process).to(receive(:wait))
    allow(Signal).to(receive(:trap))
  end

  context "with default server" do
    let(:fake_server) { instance_double(SidekiqAlive::Server::Default, start: nil, stop: nil, join: nil) }

    before do
      allow(SidekiqAlive::Server::Default).to(receive(:new).and_return(fake_server))
      allow(Thread).to(receive(:new).and_yield)
    end

    context "with default config" do
      it "starts server with default arguments and traps shutdown", :aggregate_failures do
        app.run!

        expect(Process).to(have_received(:fork)) do |&block|
          block.call

          expect(SidekiqAlive::Server::Default).to(have_received(:new).with(7433, "0.0.0.0", "/"))
          expect(fake_server).to(have_received(:start))
          expect(fake_server).to(have_received(:join))
          expect(Signal).to(have_received(:trap).with("TERM")) do |&arg|
            arg.call

            expect(fake_server).to(have_received(:stop))
          end
        end
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

        expect(Process).to(have_received(:fork)) do |&block|
          block.call

          expect(SidekiqAlive::Server::Default).to(have_received(:new).with(4567, "1.2.3.4", "/health"))
        end
      end
    end
  end

  context "rack based server" do
    let(:fake_server) { double("rack server", run: nil, shutdown: nil) }
    let(:handler) { SidekiqAlive::Helpers.use_rackup? ? Rackup::Handler : Rack::Handler }

    before do
      ENV["SIDEKIQ_ALIVE_SERVER"] = "webrick"
      SidekiqAlive.config.set_defaults

      allow(handler).to(receive(:get).and_return(fake_server))
    end

    after { ENV["SIDEKIQ_ALIVE_SERVER"] = nil }

    context "with default config" do
      it "starts server with default arguments and traps shutdown", :aggregate_failures do
        app.run!

        expect(Process).to(have_received(:fork)) do |&block|
          block.call

          expect(handler).to(have_received(:get).with("webrick"))
          expect(fake_server).to(have_received(:run).with(
            SidekiqAlive::Server::Rack, Port: 7433, Host: "0.0.0.0", AccessLog: [], Logger: SidekiqAlive.logger
          ))
          expect(Signal).to(have_received(:trap).with("TERM")) do |&arg|
            arg.call

            expect(fake_server).to(have_received(:shutdown))
          end
        end
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

        expect(Process).to(have_received(:fork)) do |&block|
          block.call

          expect(fake_server).to(have_received(:run).with(
            SidekiqAlive::Server::Rack, Port: 4567, Host: "1.2.3.4", AccessLog: [], Logger: SidekiqAlive.logger
          ))
        end
      end
    end
  end
end
