module SidekiqAlive
  class Config
    include Singleton

    attr_accessor :port,
                  :liveness_key,
                  :time_to_live,
                  :registration_ttl,
                  :callback,
                  :registered_instance_key,
                  :preferred_queue,
                  :delay_between_async_other_host_queue

    def initialize
      set_defaults
    end

    def set_defaults
      @port = ENV['SIDEKIQ_ALIVE_PORT'] || 7433
      @liveness_key = 'SIDEKIQ::LIVENESS_PROBE_TIMESTAMP'
      @time_to_live = 5 * 60
      @registration_ttl = (5 * 60) + 60
      @callback = proc {}
      @registered_instance_key = 'SIDEKIQ_REGISTERED_INSTANCE'
      @preferred_queue = :sidekiq_alive
      @delay_between_async_other_host_queue = 2 # in seconds
    end

  end
end
