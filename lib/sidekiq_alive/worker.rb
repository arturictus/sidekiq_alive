module SidekiqAlive
  class Worker
    include Sidekiq::Worker
    def perform
      do_snitch
      write_living_check
      self.class.perform_in(3.minutes)
    end

    def do_snitch
      # TODO use form config
      snitch = ENV['SIDEKIQ_SNITCH']
      return unless snitch
      HTTP.get(snitch)
    rescue
      # nop
    end

    def write_living_check
      # TODO use from config
      SidekiqAlive::Server.store_alive_key
    end
  end
end
