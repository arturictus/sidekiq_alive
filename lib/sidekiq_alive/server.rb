require 'rack'

module SidekiqAlive
  class Server
    class << self
      def run!
        Rack::Handler.get(server).run(self, :Port => port, :Host => '0.0.0.0')
      end

      def port
        SidekiqAlive.config.port
      end

      def server
        SidekiqAlive.config.server
      end

      def call(env)
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
end
