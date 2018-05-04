require "sidekiq_alive/version"
require 'sidekiq'

module SidekiqAlive
  def self.start
    Sidekiq.configure_server do |config|
      config.on(:startup) do
        SidekiqAlive::Server.start
      end
    end
  end

  def self.setup
    yield(self)
  end

  def self.port=(port)
    @port = port
  end

  def self.port
    @port || 7433
  end

  def self.liveness_key=(key)
    @liveness_key = key
  end

  def self.liveness_key
    @liveness_key || "SIDEKIQ::LIVENESS_PROBE_TIMESTAMP"
  end

  def self.time_to_live=(time)
    @time_to_live = time
  end

  def self.time_to_live
    @time_to_live || 10 * 60
  end

  def self.after_storing_key=(block)
    @after_storing_key = block
  end

  def self.after_storing_key
    @after_storing_key || proc {} # do nothing
  end

  def self.before_storing_key=(block)
    @before_storing_key = block
  end

  def self.before_storing_key
    @before_storing_key || proc {} # do nothing
  end

end

require 'sidekiq_alive/server'
require 'sidekiq_alive/worker'
