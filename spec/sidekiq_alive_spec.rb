# frozen_string_literal: true

begin
  # this is needed for spec to work with sidekiq >7
  require "sidekiq/capsule"
rescue LoadError # rubocop:disable Lint/SuppressedException
end

RSpec.describe(SidekiqAlive) do
  context "with configuration" do
    it "has a version number" do
      expect(SidekiqAlive::VERSION).not_to(be(nil))
    end

    it "configures the host from the #setup" do
      described_class.setup do |config|
        config.host = "1.2.3.4"
      end

      expect(described_class.config.host).to(eq("1.2.3.4"))
    end

    it "configures the host from the SIDEKIQ_ALIVE_HOST ENV var" do
      ENV["SIDEKIQ_ALIVE_HOST"] = "1.2.3.4"

      SidekiqAlive.config.set_defaults

      expect(described_class.config.host).to(eq("1.2.3.4"))

      ENV["SIDEKIQ_ALIVE_HOST"] = nil
    end

    it "configures the port from the #setup" do
      described_class.setup do |config|
        config.port = 4567
      end

      expect(described_class.config.port).to(eq(4567))
    end

    it "configures the port from the SIDEKIQ_ALIVE_PORT ENV var" do
      ENV["SIDEKIQ_ALIVE_PORT"] = "4567"

      SidekiqAlive.config.set_defaults

      expect(described_class.config.port).to(eq("4567"))

      ENV["SIDEKIQ_ALIVE_PORT"] = nil
    end

    it "configures the concurrency from the SIDEKIQ_ALIVE_CONCURRENCY ENV var" do
      ENV["SIDEKIQ_ALIVE_CONCURRENCY"] = "3"

      SidekiqAlive.config.set_defaults

      expect(described_class.config.concurrency).to(eq(3))

      ENV["SIDEKIQ_ALIVE_CONCURRENCY"] = nil
    end

    it "configurations behave as expected" do
      k = described_class.config

      expect(k.host).to(eq("0.0.0.0"))
      k.host = "1.2.3.4"
      expect(k.host).to(eq("1.2.3.4"))

      expect(k.port).to(eq(7433))
      k.port = 4567
      expect(k.port).to(eq(4567))

      expect(k.liveness_key).to(eq("SIDEKIQ::LIVENESS_PROBE_TIMESTAMP"))
      k.liveness_key = "key"
      expect(k.liveness_key).to(eq("key"))

      expect(k.time_to_live).to(eq(10 * 60))
      k.time_to_live = 2 * 60
      expect(k.time_to_live).to(eq(2 * 60))

      expect(k.callback.call).to(eq(nil))
      k.callback = proc { "hello" }
      expect(k.callback.call).to(eq("hello"))

      expect(k.queue_prefix).to(eq(:"sidekiq-alive"))
      k.queue_prefix = :other
      expect(k.queue_prefix).to(eq(:other))

      expect(k.shutdown_callback.call).to(eq(nil))
      k.shutdown_callback = proc { "hello" }
      expect(k.shutdown_callback.call).to(eq("hello"))
    end
  end

  context "with redis" do
    let(:sidekiq_7) { SidekiqAlive::Helpers.sidekiq_7 }
    # Older versions of sidekiq yielded Sidekiq module as configuration object
    # With sidekiq > 7, configuration is a separate class
    let(:sq_config) { sidekiq_7 ? Sidekiq.default_configuration : Sidekiq }

    before do
      allow(Sidekiq).to(receive(:server?) { true })
      allow(sq_config).to(receive(:on))

      if sidekiq_7
        allow(sq_config).to(receive(:capsule).and_call_original)
      elsif sq_config.respond_to?(:[])
        allow(sq_config).to(receive(:[]).and_call_original)
      else
        allow(sq_config).to(receive(:options).and_call_original)
      end
    end

    it '::store_alive_key" stores key with the expected ttl' do
      redis = SidekiqAlive.redis

      expect(redis.ttl(SidekiqAlive.current_lifeness_key)).to(eq(-2))
      SidekiqAlive.store_alive_key
      expect(redis.ttl(SidekiqAlive.current_lifeness_key)).to(eq(SidekiqAlive.config.time_to_live))
    end

    it "::current_lifeness_key" do
      expect(SidekiqAlive.current_lifeness_key).to(include("::test-hostname"))
    end

    it "::hostname" do
      expect(SidekiqAlive.hostname).to(eq("test-hostname"))
    end

    it "::alive?" do
      expect(SidekiqAlive.alive?).to(be(false))
      SidekiqAlive.store_alive_key
      expect(SidekiqAlive.alive?).to(be(true))
    end

    context "::start" do
      let(:queue_prefix) { :heathcheck }
      let(:queues) do
        next Sidekiq.default_configuration.capsules[SidekiqAlive::CAPSULE_NAME].queues if sidekiq_7

        sq_config.options[:queues]
      end

      before do
        allow(SidekiqAlive).to(receive(:fork) { 1 })
        allow(sq_config).to(receive(:on).with(:startup) { |&arg| arg.call })

        SidekiqAlive.instance_variable_set(:@redis, nil)
      end

      it "::registered_instances" do
        SidekiqAlive.start
        expect(SidekiqAlive.registered_instances.count).to(eq(1))
        expect(SidekiqAlive.registered_instances.first).to(include("test-hostname"))
      end

      it "::unregister_current_instance" do
        SidekiqAlive.start

        expect(sq_config).to(have_received(:on).with(:quiet)) do |&arg|
          arg.call

          expect(SidekiqAlive.registered_instances.count).to(eq(0))
        end
      end

      it "::queues" do
        SidekiqAlive.config.queue_prefix = queue_prefix

        SidekiqAlive.start

        expect(queues.first).to(eq("#{queue_prefix}-test-hostname"))
      end
    end
  end
end
