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
                  :server,
                  :custom_liveness_probe,
                  :logger,
                  :shutdown_callback

    def initialize
      set_defaults
    end

    def set_defaults
      @host = ENV.fetch('SIDEKIQ_ALIVE_HOST', '0.0.0.0')
      @port = ENV.fetch('SIDEKIQ_ALIVE_PORT', 7433)
      @path = ENV.fetch('SIDEKIQ_ALIVE_PATH', '/')
      @liveness_key = 'SIDEKIQ::LIVENESS_PROBE_TIMESTAMP'
      @time_to_live = 10 * 60
      @callback = proc {}
      @registered_instance_key = 'SIDEKIQ_REGISTERED_INSTANCE'
      @queue_prefix = :"sidekiq-alive"
      @server = ENV.fetch('SIDEKIQ_ALIVE_SERVER', 'webrick')
      @custom_liveness_probe = proc { true }
      @shutdown_callback = proc {}
    end

    def registration_ttl
      @registration_ttl || time_to_live + 60
    end
  end
end
