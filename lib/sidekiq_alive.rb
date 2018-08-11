require "sidekiq"
require "singleton"
require "sidekiq_alive/version"
require "sidekiq_alive/config"

module SidekiqAlive
  def self.start
    Sidekiq.configure_server do |config|
      config.on(:startup) do
        SidekiqAlive::Worker.perform_async
        SidekiqAlive::Server.start
      end
    end
  end

  def self.store_alive_key
    redis.set(config.liveness_key,
              Time.now.to_i,
              { ex: config.time_to_live.to_i })
  end

  def self.redis
    Sidekiq.redis { |r| r }
  end

  def self.alive?
    redis.ttl(config.liveness_key) == -2 ? false : true
  end

  # CONFIG ---------------------------------------

  def self.setup
    yield(config)
  end

  def self.config
    @config ||= SidekiqAlive::Config.instance
  end
end

require "sidekiq_alive/worker"
require "sidekiq_alive/server"
