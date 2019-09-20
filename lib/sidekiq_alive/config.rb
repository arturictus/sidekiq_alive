module SidekiqAlive
  class Config
    include Singleton

    attr_accessor :port,
                  :server,
                  :liveness_key,
                  :time_to_live,
                  :callback,
                  :registered_instance_key,
                  :preferred_queue,
                  :delay_between_async_other_host_queue
    attr_writer :registration_ttl

    def initialize
      set_defaults
    end

    def set_defaults
      @port = ENV['SIDEKIQ_ALIVE_PORT'] || 7433
      @server = ENV['SIDEKIQ_ALIVE_SERVER'] || :thin
      @liveness_key = 'SIDEKIQ::LIVENESS_PROBE_TIMESTAMP'
      @time_to_live = 10 * 60
      @callback = proc {}
      @registered_instance_key = 'SIDEKIQ_REGISTERED_INSTANCE'
      @preferred_queue = :sidekiq_alive
      @delay_between_async_other_host_queue = 1 # in seconds
    end

    def registration_ttl
      @registration_ttl ? @registration_ttl : time_to_live + 60
    end
  end
end
