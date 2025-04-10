# frozen_string_literal: true

RSpec.describe(SidekiqAlive::Config) do
  subject(:config) { described_class.instance }

  describe "#worker_interval" do
    it "less than ttl" do
      expect(config.worker_interval).to(satisfy { |i| i < config.time_to_live })
    end
  end
end
