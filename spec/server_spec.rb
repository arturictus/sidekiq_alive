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

RSpec.describe(SidekiqAlive::Server, :aggregate_failures) do
  subject(:app) { described_class }

  let(:pid) { Random.rand(1000) }

  before do
    allow(Process).to(receive(:fork).and_yield.and_return(pid))
    allow(Process).to(receive(:kill))
    allow(Process).to(receive(:wait))
    allow(Signal).to(receive(:trap))
    allow(Kernel).to(receive(:at_exit))
  end

  context "with default server" do
    let(:fake_server) do
      instance_double(
        SidekiqAlive::Server::Default,
        start: nil,
        stop: nil,
        join: nil,
        quiet!: nil,
      )
    end

    before do
      allow(SidekiqAlive::Server::Default).to(receive(:new).and_return(fake_server))
      allow(Thread).to(receive(:new).and_yield)

      app.run!
    end

    context "with default config" do
      it "starts server with default arguments and configures lifecycle" do
        expect(SidekiqAlive::Server::Default).to(have_received(:new).with(7433, "0.0.0.0", "/"))
        expect(fake_server).to(have_received(:start))
        expect(fake_server).to(have_received(:join))
      end

      it "configures signals" do
        expect(Signal).to(have_received(:trap).with("TERM")) do |&arg|
          arg.call

          expect(fake_server).to(have_received(:stop))
        end
        expect(Signal).to(have_received(:trap).with("USR1")) do |&arg|
          arg.call

          expect(fake_server).to(have_received(:quiet!))
        end
      end

      it "configures shutdown" do
        allow(Kernel).to(receive(:at_exit)) do |&arg|
          arg.call

          expect(Process).to(have_received(:kill).with("TERM", pid))
          expect(Process).to(have_received(:wait).with(pid))
        end
      end
    end

    context "with changed host, port and path configuration" do
      around(&around_config)

      it "starts with updated configuration" do
        expect(SidekiqAlive::Server::Default).to(have_received(:new).with(4567, "1.2.3.4", "/health"))
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
      SidekiqAlive::Server::Rack.instance_variable_set(:@quiet, nil)

      app.run!
    end

    after { ENV["SIDEKIQ_ALIVE_SERVER"] = nil }

    context "with default config" do
      it "starts server with default arguments and traps shutdown", :aggregate_failures do
        expect(handler).to(have_received(:get).with("webrick"))
        expect(fake_server).to(have_received(:run).with(
          SidekiqAlive::Server::Rack, Port: 7433, Host: "0.0.0.0", AccessLog: [], Logger: SidekiqAlive.logger
        ))
      end

      it "configures signals" do
        expect(Signal).to(have_received(:trap).with("TERM")) do |&arg|
          arg.call

          expect(fake_server).to(have_received(:shutdown))
        end
        expect(Signal).to(have_received(:trap).with("USR1")) do |&arg|
          arg.call

          expect(SidekiqAlive::Server::Rack.instance_variable_get(:@quiet)).to(be_instance_of(Time))
        end
      end

      it "configures shutdown" do
        allow(Kernel).to(receive(:at_exit)) do |&arg|
          arg.call

          expect(Process).to(have_received(:kill).with("TERM", pid))
          expect(Process).to(have_received(:wait).with(pid))
        end
      end
    end

    context "with changed host, port and path configuration" do
      around(&around_config)

      it "starts with updated configuration" do
        expect(fake_server).to(have_received(:run).with(
          SidekiqAlive::Server::Rack, Port: 4567, Host: "1.2.3.4", AccessLog: [], Logger: SidekiqAlive.logger
        ))
      end
    end
  end
end
