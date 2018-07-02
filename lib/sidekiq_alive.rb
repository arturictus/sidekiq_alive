require "sidekiq_alive/version"
require 'sidekiq'
require 'pry'

module SidekiqAlive
  def self.start
    Sidekiq.configure_server do |config|
      config.on(:startup) do
        SidekiqAlive::Server.start
      end
    end
  end

  def self.store_alive_key
    redis.set(liveness_key,
              Time.now.to_i,
              { ex: time_to_live.to_i })
  end

  def self.redis
    Sidekiq.redis { |r| r }
  end

  def self.alive?
    redis.ttl(liveness_key) == -2 ? false : true
  end

  def self.queue_with_variant
    "#{queue_name}-#{queue_variant}"
  end

  # CONFIG ---------------------------------------

  def self.setup
    yield(self)
  end

  def self.port=(port)
    @port = port
  end

  def self.port
    @port || 7433
  end

  def self.queue_name=(queue_name)
    @queue_name = queue_name.to_s
  end

  def self.queue_variant=(variant)
    @queue_variant = variant.to_s
  end

  def self.queue_name
    @queue_name || "default"
  end

  def self.queue_variant
    @queue_variant ||= Time.now.to_i.to_s
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

  def self.callback=(block)
    @after_storing_key = block
  end

  def self.callback
    @after_storing_key || proc {} # do nothing
  end

end

require 'sidekiq_alive/server'
require 'sidekiq_alive/worker'
