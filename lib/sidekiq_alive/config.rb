module SidekiqAlive
  class Config
    include Singleton

    attr_accessor :port, :liveness_key, :time_to_live, :callback

    def initialize
      @port = 7433
      @liveness_key = 'SIDEKIQ::LIVENESS_PROBE_TIMESTAMP'
      @time_to_live = 10 * 60
      @callback = proc {}
    end
  end
end
