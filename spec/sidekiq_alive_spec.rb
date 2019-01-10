RSpec.describe SidekiqAlive do

  it "has a version number" do
    expect(SidekiqAlive::VERSION).not_to be nil
  end

  it 'configurations behave as expected' do
    k = described_class.config
    expect(k.port).to eq 7433
    k.port = 4567
    expect(k.port).to eq 4567

    expect(k.liveness_key).to eq "SIDEKIQ::LIVENESS_PROBE_TIMESTAMP"
    k.liveness_key = 'key'
    expect(k.liveness_key).to eq 'key'

    expect(k.time_to_live).to eq 10 * 60
    k.time_to_live = 2 * 60
    expect(k.time_to_live).to eq 2 * 60

    expect(k.callback.call()).to eq nil
    k.callback = proc{ 'hello' }
    expect(k.callback.call()).to eq 'hello'

    expect(k.preferred_queue).to eq :default
    k.preferred_queue = :sidekiq_alive
    expect(k.preferred_queue).to eq :sidekiq_alive
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
    expect(SidekiqAlive.current_lifeness_key).to include "::test-hostname"
  end
  it '::hostname' do
    expect(SidekiqAlive.hostname).to eq 'test-hostname'
  end

  it "::alive?" do
    redis = SidekiqAlive.redis
    expect(SidekiqAlive.alive?).to be false
    SidekiqAlive.store_alive_key
    expect(SidekiqAlive.alive?).to be true
  end

  it "::registered_instances" do
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
