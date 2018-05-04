RSpec.describe SidekiqAlive do

  it "has a version number" do
    expect(SidekiqAlive::VERSION).not_to be nil
  end

  it 'configurations behave as expected' do
    k = described_class
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
  end

  before do
    allow(SidekiqAlive).to receive(:redis).and_return(MockRedis.new)
  end

  it '::store_alive_key" stores key with the expected ttl' do
    redis = SidekiqAlive.redis
    expect(redis.ttl(SidekiqAlive.liveness_key)).to eq -2
    SidekiqAlive.store_alive_key
    expect(redis.ttl(SidekiqAlive.liveness_key)).to eq SidekiqAlive.time_to_live
  end

  it "::alive?" do
    redis = SidekiqAlive.redis
    expect(SidekiqAlive.alive?).to be false
    SidekiqAlive.store_alive_key
    expect(SidekiqAlive.alive?).to be true
  end

end
