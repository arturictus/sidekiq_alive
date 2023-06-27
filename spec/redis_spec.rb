# frozen_string_literal: true

RSpec.describe(SidekiqAlive::Redis) do
  let(:redis) { SidekiqAlive::Redis.adapter }

  it "Works" do
    time = Time.now.to_s
    redis.set("hello", time: time, ex: 60)
    expect(redis.ttl("hello") > 1).to(be(true))
    expect(redis.get("hello")).to(eq(time))
    redis.zadd("test_set", Time.now.to_i, "test-key-1")
    redis.zadd("test_set", Time.now.to_i, "test-key-2")
    expect(redis.zrange("test_set", 0, -1)).to(eq(["test-key-1", "test-key-2"]))
    expect(redis.zrem("test_set", "test-key-1"))
    expect(redis.zrange("test_set", 0, -1)).to(eq(["test-key-2"]))
  end
end
