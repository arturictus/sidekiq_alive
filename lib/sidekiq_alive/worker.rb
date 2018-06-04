module SidekiqAlive
  class Worker
    include Sidekiq::Worker
    sidekiq_options retry: false, queue: SidekiqAlive.queue_name

    def perform
      write_living_probe
      Sidekiq::Client.enqueue_to_in(SidekiqAlive.queue_name, SidekiqAlive.time_to_live / 2, self.class)
    end

    def write_living_probe
      # Write liveness probe
      SidekiqAlive.store_alive_key
      # after callbacks
      SidekiqAlive.callback.call()
    end
  end
end
