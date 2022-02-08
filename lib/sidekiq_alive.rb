require 'sidekiq'
require 'sidekiq/api'
require 'singleton'
require 'sidekiq_alive/version'
require 'sidekiq_alive/config'

module SidekiqAlive
  def self.start
    SidekiqAlive::Worker.sidekiq_options queue: current_queue
    Sidekiq.configure_server do |sq_config|

      sq_config.options[:queues].unshift(current_queue)

      sq_config.on(:startup) do
        SidekiqAlive.tap do |sa|
          sa.logger.info(banner)
          sa.register_current_instance
          sa.store_alive_key
          sa::Worker.perform_async(hostname)
          @server_pid = fork do
            sa::Server.run!
          end
          sa.logger.info(successful_startup_text)
        end
      end

      sq_config.on(:quiet) do
        SidekiqAlive.unregister_current_instance
      end

      sq_config.on(:shutdown) do
        Process.kill('TERM', @server_pid) unless @server_pid.nil?
        Process.wait(@server_pid) unless @server_pid.nil?
        SidekiqAlive.unregister_current_instance
      end
    end
  end

  def self.current_queue
    "#{config.queue_prefix}-#{hostname}"
  end

  def self.register_current_instance
    register_instance(current_instance_register_key)
  end

  def self.unregister_current_instance
    # Delete any pending jobs for this instance
    logger.info(shutdown_info)
    purge_pending_jobs
    redis.del(current_instance_register_key)
  end

  def self.registered_instances
    deep_scan("#{config.registered_instance_key}::*")
  end

  def self.deep_scan(keyword, keys = [], cursor = 0)
    next_cursor, found_keys = *redis { |r| r }.scan(cursor, match: keyword)
    keys += found_keys
    return keys if next_cursor == "0" || found_keys.blank?
    deep_scan(keyword, keys, next_cursor)
  end

  def self.purge_pending_jobs
    # TODO:
    # Sidekiq 6 allows better way to find scheduled jobs:
    # https://github.com/mperham/sidekiq/wiki/API#scan
    scheduled_set = Sidekiq::ScheduledSet.new
    jobs = scheduled_set.select { |job| job.klass == 'SidekiqAlive::Worker' && job.queue == current_queue }
    logger.info("[SidekiqAlive] Purging #{jobs.count} pending for #{hostname}")
    jobs.each(&:delete)
    logger.info("[SidekiqAlive] Removing queue #{current_queue}")
    Sidekiq::Queue.new(current_queue).clear
  end

  def self.current_instance_register_key
    "#{config.registered_instance_key}::#{hostname}"
  end

  def self.store_alive_key
    redis.set(current_lifeness_key,
              Time.now.to_i,
              ex: config.time_to_live.to_i)
  end

  def self.redis
    Sidekiq.redis { |r| r }
  end

  def self.alive?
    redis.ttl(current_lifeness_key) != -2
  end

  # CONFIG ---------------------------------------

  def self.setup
    yield(config)
  end

  def self.logger
    Sidekiq.logger
  end

  def self.config
    @config ||= SidekiqAlive::Config.instance
  end

  def self.current_lifeness_key
    "#{config.liveness_key}::#{hostname}"
  end

  def self.hostname
    ENV['SIDEKIQ_ALIVE_HOSTNAME'] || ENV['HOSTNAME'] || 'HOSTNAME_NOT_SET'
  end

  def self.shutdown_info
    <<~BANNER

    =================== Shutting down SidekiqAlive =================

    Hostname: #{hostname}
    Liveness key: #{current_lifeness_key}
    Current instance register key: #{current_instance_register_key}

    BANNER
  end

  def self.banner
    <<~BANNER

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
    <<~BANNER
    Registered instances:

    - #{registered_instances.join("\n\s\s- ")}

    =================== SidekiqAlive Ready! =================
    BANNER
  end

  def self.register_instance(instance_name)
    redis.set(instance_name,
              Time.now.to_i,
              ex: config.registration_ttl.to_i)
  end
end

require 'sidekiq_alive/worker'
require 'sidekiq_alive/server'

SidekiqAlive.start unless ENV.fetch('DISABLE_SIDEKIQ_ALIVE', '').casecmp("true") == 0
