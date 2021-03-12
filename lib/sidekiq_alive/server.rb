# frozen_string_literal: true

require 'rack'

module SidekiqAlive
  class Server
    class << self
      def run!
        handler =  Rack::Handler.get(server)

        Signal.trap('TERM') { handler.shutdown }

        handler.run(self, Port: port, Host: host)
      end

      def host
        SidekiqAlive.config.host
      end

      def port
        SidekiqAlive.config.port
      end

      def path
        SidekiqAlive.config.path
      end

      def server
        SidekiqAlive.config.server
      end

      def call(env)
        if Rack::Request.new(env).path != path
          [404, {}, ['Not found']]
        elsif SidekiqAlive.alive?
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
