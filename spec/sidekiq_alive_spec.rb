RSpec.describe SidekiqAlive do
  it 'has a version number' do
    expect(SidekiqAlive::VERSION).not_to be nil
  end

  it 'configures the host from the #setup' do
    described_class.setup do |config|
      config.host = '1.2.3.4'
    end

    expect(described_class.config.host).to eq '1.2.3.4'
  end

  it 'configures the host from the SIDEKIQ_ALIVE_HOST ENV var' do
    ENV['SIDEKIQ_ALIVE_HOST'] = '1.2.3.4'

    SidekiqAlive.config.set_defaults

    expect(described_class.config.host).to eq '1.2.3.4'

    ENV['SIDEKIQ_ALIVE_HOST'] = nil
  end

  it 'configures the port from the #setup' do
    described_class.setup do |config|
      config.port = 4567
    end

    expect(described_class.config.port).to eq 4567
  end

  it 'configures the port from the SIDEKIQ_ALIVE_PORT ENV var' do
    ENV['SIDEKIQ_ALIVE_PORT'] = '4567'

    SidekiqAlive.config.set_defaults

    expect(described_class.config.port).to eq '4567'

    ENV['SIDEKIQ_ALIVE_PORT'] = nil
  end

  it 'configurations behave as expected' do
    k = described_class.config

    expect(k.host).to eq '0.0.0.0'
    k.host = '1.2.3.4'
    expect(k.host).to eq '1.2.3.4'

    expect(k.port).to eq 7433
    k.port = 4567
    expect(k.port).to eq 4567

    expect(k.liveness_key).to eq 'SIDEKIQ::LIVENESS_PROBE_TIMESTAMP'
    k.liveness_key = 'key'
    expect(k.liveness_key).to eq 'key'

    expect(k.time_to_live).to eq 10 * 60
    k.time_to_live = 2 * 60
    expect(k.time_to_live).to eq 2 * 60

    expect(k.callback.call).to eq nil
    k.callback = proc { 'hello' }
    expect(k.callback.call).to eq 'hello'

    expect(k.queue_prefix).to eq :sidekiq_alive
    k.queue_prefix = :other
    expect(k.queue_prefix).to eq :other
  end

  describe '::start' do
    before do
      allow(Sidekiq).to receive(:server?).and_return(true)
    end

    it 'prepend sidekiq alive queue' do
      Sidekiq[:queues] = ['default']
      SidekiqAlive.start

      expect(Sidekiq[:queues].first).to eq(described_class.current_queue)
    end
  end

  before do
    allow(SidekiqAlive).to receive(:redis).and_return(MockRedis.new)
  end

  it '::store_alive_key" stores key with the expected ttl' do
    redis = SidekiqAlive.redis
    expect(redis.ttl(SidekiqAlive.current_lifeness_key)).to eq -2
    SidekiqAlive.store_alive_key
    expect(redis.ttl(SidekiqAlive.current_lifeness_key)).to eq SidekiqAlive.config.time_to_live
  end

  it '::current_lifeness_key' do
    expect(SidekiqAlive.current_lifeness_key).to include '::test-hostname'
  end
  it '::hostname' do
    expect(SidekiqAlive.hostname).to eq 'test-hostname'
  end

  it '::alive?' do
    redis = SidekiqAlive.redis
    expect(SidekiqAlive.alive?).to be false
    SidekiqAlive.store_alive_key
    expect(SidekiqAlive.alive?).to be true
  end

  it '::registered_instances' do
    [*(1..1000)].each do |n|
      SidekiqAlive.redis.set("#{n}-value",
      Time.now.to_i,
      ex: 60)
    end
    expect(SidekiqAlive.registered_instances).to eq []
    SidekiqAlive.register_current_instance
    expect(SidekiqAlive.registered_instances.count).to eq 1
    expect(SidekiqAlive.registered_instances.first).to include 'test-hostname'
  end

  it '::unregister_current_instance' do
    SidekiqAlive.register_current_instance
    expect(SidekiqAlive.registered_instances.count).to eq 1
    SidekiqAlive.unregister_current_instance
    expect(SidekiqAlive.registered_instances.count).to eq 0
  end
end
