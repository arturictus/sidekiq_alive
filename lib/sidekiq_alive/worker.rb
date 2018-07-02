require "sidekiq/api"
module SidekiqAlive
  class Worker
    include Sidekiq::Worker
    sidekiq_options retry: false, queue: SidekiqAlive.queue_with_variant

    def perform
      write_living_probe
      clean_old_queues
      Sidekiq::Client.enqueue_to_in(SidekiqAlive.queue_with_variant, SidekiqAlive.time_to_live / 2, self.class)
    end

    def clean_old_queues
      Sidekiq::Queue.all.each do |queue|
        queue.clear if queue.name =~ /#{SidekiqAlive.queue_name}/ && queue.latency > SidekiqAlive.time_to_live
      end
    end

    def write_living_probe
      # Write liveness probe
      SidekiqAlive.store_alive_key
      # after callbacks
      SidekiqAlive.callback.call()
    end
  end
end
