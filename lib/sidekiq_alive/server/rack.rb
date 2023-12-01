# frozen_string_literal: true

module SidekiqAlive
  module Server
    class Rack
      class << self
        def run!
          @handler = handler

          Signal.trap("TERM") { @handler.shutdown }

          @server_pid = fork { @handler.run(self, Port: port, Host: host, AccessLog: [], Logger: SidekiqAlive.logger) }

          self
        end

        def shutdown!
          Process.kill("TERM", @server_pid) unless @server_pid.nil?
          Process.wait(@server_pid) unless @server_pid.nil?
        end

        def call(env)
          if ::Rack::Request.new(env).path != path
            [404, {}, ["Not found"]]
          elsif SidekiqAlive.alive?
            [200, {}, ["Alive!"]]
          else
            response = "Can't find the alive key"
            SidekiqAlive.logger.error(response)
            [404, {}, [response]]
          end
        end

        private

        def handler
          Helpers.use_rackup? ? ::Rackup::Handler.get(server) : ::Rack::Handler.get(server)
        end

        def host
          SidekiqAlive.config.host
        end

        def port
          SidekiqAlive.config.port.to_i
        end

        def path
          SidekiqAlive.config.path
        end

        def server
          SidekiqAlive.config.server
        end
      end
    end
  end
end
