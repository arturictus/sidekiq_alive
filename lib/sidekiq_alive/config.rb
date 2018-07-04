module SidekiqAlive
  class Config
    include Singleton

    attr_accessor :port, :queue_name, :queue_variant, :liveness_key, :time_to_live, :callback

    def initialize
      @port = 7433
      @queue_name = 'default'
      @queue_variant = Time.now.to_i
      @liveness_key = 'SIDEKIQ::LIVENESS_PROBE_TIMESTAMP'
      @time_to_live = 10 * 60
      @callback = proc {}
    end

    def queue_with_variant
      "#{queue_name}-#{queue_variant}"
    end
  end
end
