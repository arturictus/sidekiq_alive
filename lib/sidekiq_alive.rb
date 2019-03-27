require "sidekiq"
require "singleton"
require "sidekiq_alive/version"
require "sidekiq_alive/config"

module SidekiqAlive
  def self.start
    Sidekiq.configure_server do |config|

      SidekiqAlive::Worker.sidekiq_options queue: SidekiqAlive.select_queue(config.options[:queues])

      config.on(:startup) do
        SidekiqAlive.tap do |sa|
          sa.logger.info(banner)
          sa.register_current_instance
          sa.store_alive_key
          sa::Worker.perform_async(hostname)
          sa::Server.start
          sa.logger.info(successful_startup_text)
        end
      end

      config.on(:quiet) do
        SidekiqAlive.unregister_current_instance
      end
      config.on(:shutdown) do
        SidekiqAlive.unregister_current_instance
      end
    end

  end

  def self.select_queue(queues)
    @queue = if queues.find { |e| e.to_sym == config.preferred_queue.to_sym }
               config.preferred_queue.to_sym
             else
               queues.first
             end
  end

  def self.register_current_instance
    register_instance(current_instance_register_key)
  end

  def self.unregister_current_instance
    # Delete any pending jobs for this instance
    purge_pending_jobs
    redis.del(current_instance_register_key)
  end

  def self.registered_instances
    redis.keys("#{config.registered_instance_key}::*")
  end

  def self.purge_pending_jobs
    scheduled_set = Sidekiq::ScheduledSet.new
    jobs = scheduled_set.select { |job| job.klass == 'SidekiqAlive::Worker' && job.args[0] == hostname }
    jobs.each(&:delete)
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
    Worker running on queue: #{@queue}


    starting ...
    BANNER
  end

  def self.successful_startup_text
    <<-BANNER.strip_heredoc
    Registered instances:

    - #{registered_instances.join("\n\s\s- ")}

    =================== SidekiqAlive Ready! =================
    BANNER
  end

  def self.register_instance(instance_name)
    redis.set(instance_name,
              Time.now.to_i,
              { ex: config.registration_ttl.to_i })
  end
end

require "sidekiq_alive/worker"
require "sidekiq_alive/server"

SidekiqAlive.start unless ENV['DISABLE_SIDEKIQ_ALIVE']
