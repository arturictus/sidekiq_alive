require "sidekiq"
require "singleton"
require "sidekiq_alive/version"
require "sidekiq_alive/config"

module SidekiqAlive
  def self.start
    Sidekiq.configure_server do |config|
      config.on(:startup) do
        SidekiqAlive.tap do |sa|
          sa.logger.info(banner)
          sa.register_current_instance
          sa.store_alive_key
          sa::Worker.perform_async
          sa::Server.start
          sa.logger.info(successful_startup_text)
        end
      end
    end
  end

  def self.register_current_instance
    register_instance(current_instance_register_key)
  end

  def self.registered_instances
    redis.keys("#{config.registered_instance_key}::*")
  end

  def self.current_instance_register_key
    "#{config.registered_instance_key}::#{hostname}"
  end

  def self.store_alive_key
    redis.set(current_lifeness_key,
              Time.now.to_i,
              { ex: config.time_to_live.to_i })
  end

  def self.redis
    Sidekiq.redis { |r| r }
  end

  def self.alive?
    redis.ttl(current_lifeness_key) == -2 ? false : true
  end

  # CONFIG ---------------------------------------

  def self.setup
    yield(config)
  end

  def self.logger
    Sidekiq::Logging.logger
  end

  def self.config
    @config ||= SidekiqAlive::Config.instance
  end

  def self.current_lifeness_key
    "#{config.liveness_key}::#{hostname}"
  end

  def self.hostname
    ENV['HOSTNAME'] || 'HOSTNAME_NOT_SET'
  end

  def self.banner
    <<-BANNER.strip_heredoc
    =================== SidekiqAlive =================

    Hostname: #{hostname}
    Liveness key: #{current_lifeness_key}
    Port: #{config.port}
    Time to live: #{config.time_to_live}s
    Current instance register key: #{current_instance_register_key}

    starting ...
    BANNER
  end

  def self.successful_startup_text
    <<-BANNER.strip_heredoc
    =================== SidekiqAlive Ready! =================

    Registered instances:

      - #{registered_instances.join("\n\s\s- ")}
    BANNER
  end

  def self.register_instance(instance_name)
    redis.set(instance_name,
              Time.now.to_i,
              { ex: config.time_to_live.to_i + 60 })
  end
end

require "sidekiq_alive/worker"
require "sidekiq_alive/server"

SidekiqAlive.start unless ENV['DISABLE_SIDEKIQ_ALIVE']
