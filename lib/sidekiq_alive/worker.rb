module SidekiqAlive
  class Worker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(hostname = SidekiqAlive.hostname)
      write_living_probe
      # schedule next living probe
      self.class.perform_in(config.time_to_live / 2, current_hostname)
    end

    def hostname_registered?(hostname)
      SidekiqAlive.registered_instances.any? do |ri|
        /#{hostname}/ =~ ri
      end
    end

    def write_living_probe
      # Write liveness probe
      SidekiqAlive.store_alive_key
      # Increment ttl for current registered instance
      SidekiqAlive.register_current_instance
      # after callbacks
      config.callback.call() rescue nil
    end

    def current_hostname
      SidekiqAlive.hostname
    end

    def config
      SidekiqAlive.config
    end
  end
end
