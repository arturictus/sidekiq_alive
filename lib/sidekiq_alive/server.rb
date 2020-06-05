require 'rack'

module SidekiqAlive
  class Server
    def self.run!
      Rack::Handler::WEBrick.run(self, :Port => port, :Host => '0.0.0.0')
    end

    def self.port
      SidekiqAlive.config.port
    end

    def self.call(env)
      if SidekiqAlive.alive?
        [200, {}, ['Alive!']]
      else
        response = "Can't find the alive key"
        SidekiqAlive.logger.error(response)
        [404, {}, [response]]
      end
    end
  end
end
