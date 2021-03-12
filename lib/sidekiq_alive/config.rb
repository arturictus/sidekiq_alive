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
                  :server

    def initialize
      set_defaults
    end

    def set_defaults
      @host = ENV['SIDEKIQ_ALIVE_HOST'] || '0.0.0.0'
      @port = ENV['SIDEKIQ_ALIVE_PORT'] || 7433
      @path = ENV['SIDEKIQ_ALIVE_PATH'] || '/'
      @liveness_key = 'SIDEKIQ::LIVENESS_PROBE_TIMESTAMP'
      @time_to_live = 10 * 60
      @callback = proc {}
      @registered_instance_key = 'SIDEKIQ_REGISTERED_INSTANCE'
      @queue_prefix = :sidekiq_alive
      @server = ENV['SIDEKIQ_ALIVE_SERVER'] || 'webrick'
    end

    def registration_ttl
      @registration_ttl || time_to_live + 60
    end
  end
end
