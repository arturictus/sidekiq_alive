module SidekiqAlive
  class Config
    include Singleton

    attr_accessor :port, :liveness_key, :time_to_live, :callback
    attr_reader :queue_name, :queue_variant

    def initialize
      @port = 7433
      @queue_name = 'sidekiq_alive'
      @queue_variant = `hostname`.strip
      @liveness_key = 'SIDEKIQ::LIVENESS_PROBE_TIMESTAMP'
      @time_to_live = 10 * 60
      @callback = proc {}
    end

    def queue_with_variant
      "#{queue_name}-#{queue_variant}"
    end
  end
end
