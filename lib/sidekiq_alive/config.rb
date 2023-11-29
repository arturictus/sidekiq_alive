# frozen_string_literal: true

module SidekiqAlive
  class Config
    include Singleton

    attr_accessor :host,
                  :port,
                  :path,
                  :liveness_key,
                  :time_to_live,
                  :callback,
                  :registered_instance_key,
                  :queue_prefix,
                  :custom_liveness_probe,
                  :logger,
                  :shutdown_callback,
                  :concurrency

    def initialize
      set_defaults
    end

    def set_defaults
      @host = ENV.fetch("SIDEKIQ_ALIVE_HOST", "0.0.0.0")
      @port = ENV.fetch("SIDEKIQ_ALIVE_PORT", 7433)
      @path = ENV.fetch("SIDEKIQ_ALIVE_PATH", "/")
      @liveness_key = "SIDEKIQ::LIVENESS_PROBE_TIMESTAMP"
      @time_to_live = 10 * 60
      @callback = proc {}
      @registered_instance_key = "SIDEKIQ_REGISTERED_INSTANCE"
      @queue_prefix = :"sidekiq-alive"
      @custom_liveness_probe = proc { true }
      @shutdown_callback = proc {}
      @concurrency = Integer(ENV.fetch("SIDEKIQ_ALIVE_CONCURRENCY", 2), exception: false) || 2
    end

    def registration_ttl
      @registration_ttl || time_to_live * 3
    end
  end
end
