# frozen_string_literal: true

require "sidekiq"
require "sidekiq/api"
require "singleton"
require "sidekiq_alive/version"
require "sidekiq_alive/config"
require "sidekiq_alive/helpers"
require "sidekiq_alive/redis/client"
require "sidekiq_alive/redis/client_adapter"

module SidekiqAlive
  class << self
    def start
      Sidekiq.configure_server do |sq_config|
        sq_config.on(:startup) do
          SidekiqAlive::Worker.sidekiq_options(queue: current_queue)
          if Helpers.sidekiq_7
            sq_config.queues
          else
            sq_config.respond_to?(:[]) ? sq_config[:queues] : sq_config.options[:queues]
          end.unshift(current_queue)

          logger.info(startup_info)

          register_current_instance
          store_alive_key
          SidekiqAlive::Worker.perform_async(hostname)
          @server_pid = fork { SidekiqAlive::Server.run! }

          logger.info(successful_startup_text)
        end

        sq_config.on(:quiet) do
          unregister_current_instance
          config.shutdown_callback.call
        end

        sq_config.on(:shutdown) do
          Process.kill("TERM", @server_pid) unless @server_pid.nil?
          Process.wait(@server_pid) unless @server_pid.nil?

          unregister_current_instance
          config.shutdown_callback.call
        end
      end
    end

    def current_queue
      "#{config.queue_prefix}-#{hostname}"
    end

    def register_current_instance
      register_instance(current_instance_register_key)
    end

    def unregister_current_instance
      # Delete any pending jobs for this instance
      logger.info(shutdown_info)
      purge_pending_jobs
      redis.delete(current_instance_register_key)
    end

    def registered_instances
      redis.match("#{config.registered_instance_key}::*")
    end

    def purge_pending_jobs
      schedule_set = Sidekiq::ScheduledSet.new
      jobs = if Helpers.sidekiq_5
        schedule_set.select { |job| job.klass == "SidekiqAlive::Worker" && job.queue == current_queue }
      else
        schedule_set.scan('"class":"SidekiqAlive::Worker"')
      end
      logger.info("[SidekiqAlive] Purging #{jobs.count} pending for #{hostname}")
      jobs.each(&:delete)

      logger.info("[SidekiqAlive] Removing queue #{current_queue}")
      Sidekiq::Queue.new(current_queue).clear
    end

    def current_instance_register_key
      "#{config.registered_instance_key}::#{hostname}"
    end

    def store_alive_key
      redis.set(current_lifeness_key, time: Time.now.to_i, ex: config.time_to_live.to_i)
    end

    def redis
      @redis ||= Helpers.sidekiq_7 ? Redis::ClientAdapter.new : Redis::Client.new
    end

    def alive?
      redis.ttl(current_lifeness_key) != -2
    end

    # CONFIG ---------------------------------------

    def setup
      yield(config)
    end

    def logger
      config.logger || Sidekiq.logger
    end

    def config
      @config ||= SidekiqAlive::Config.instance
    end

    def current_lifeness_key
      "#{config.liveness_key}::#{hostname}"
    end

    def hostname
      ENV["HOSTNAME"] || "HOSTNAME_NOT_SET"
    end

    def shutdown_info
      "Shutting down sidekiq-alive!"
    end

    def startup_info
      info = {
        hostname: hostname,
        port: config.port,
        ttl: config.time_to_live,
        queue: current_queue,
        liveness_key: current_lifeness_key,
        register_key: current_instance_register_key,
      }

      "Starting sidekiq-alive: #{info}"
    end

    def successful_startup_text
      "Successfully started sidekiq-alive, registered instances: #{registered_instances.join("\n\s\s- ")}"
    end

    def register_instance(instance_name)
      redis.set(instance_name, time: Time.now.to_i, ex: config.registration_ttl.to_i)
    end
  end
end

require "sidekiq_alive/worker"
require "sidekiq_alive/server"

SidekiqAlive.start unless ENV.fetch("DISABLE_SIDEKIQ_ALIVE", "").casecmp("true").zero?
