require "sinatra/base"
require_relative "./config"
module SidekiqAlive
  class Server < Sinatra::Base
    set :bind, '0.0.0.0'

    class << self
      def start
        Sidekiq::Logging.logger.info "Writing SidekiqAlive alive key in redis: #{SidekiqAlive.config.liveness_key}"
        SidekiqAlive.store_alive_key
        set :port, SidekiqAlive.config.port
        Thread.start { run! }
      end

      def quit!
        super
        exit
      end
    end

    get '/' do
      if SidekiqAlive.alive?
        status 200
        body "Alive!"
      else
        response = "Can't find the alive key"
        Sidekiq::Logging.logger.error(response)
        status 404
        body response
      end
    end
  end
end
