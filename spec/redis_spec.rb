# frozen_string_literal: true

RSpec.describe(SidekiqAlive::Redis) do
  let(:redis) { SidekiqAlive::Redis.adapter }

  it "Works" do
    time = Time.now.to_s
    redis.set("hello", time: time, ex: 60)
    expect(redis.ttl("hello") > 1).to(be(true))
    expect(redis.get("hello")).to(eq(time))
    expect(redis.match("hello")).to(eq(["hello"]))
    expect(redis.delete("hello")).to(eq(1))
    expect(redis.get("hello")).to(be(nil))
  end
end
