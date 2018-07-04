require "sidekiq/api"
module SidekiqAlive
  class Worker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform
      write_living_probe
      clean_old_queues
      self.class.set(queue: config.queue_with_variant).perform_in(config.time_to_live / 2)
    end

    def clean_old_queues
      Sidekiq::Queue.all.each do |queue|
        queue.clear if queue.name =~ /#{config.queue_name}/ && queue.latency > config.time_to_live
      end
    end

    def write_living_probe
      # Write liveness probe
      SidekiqAlive.store_alive_key
      # after callbacks
      config.callback.call()
    end

    def config
      SidekiqAlive.config
    end
  end
end
