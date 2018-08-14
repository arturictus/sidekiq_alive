module SidekiqAlive
  class Worker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(hostname)
      if current_hostname == hostname
        write_living_probe
        self.class.perform_in(config.time_to_live / 2, current_hostname)
      else
        self.class.perform_async(hostname)
      end
    end

    def write_living_probe
      # Write liveness probe
      SidekiqAlive.store_alive_key
      # after callbacks
      config.callback.call()
    end

    def current_hostname
      SidekiqAlive.hostname
    end

    def config
      SidekiqAlive.config
    end
  end
end
