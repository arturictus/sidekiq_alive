# frozen_string_literal: true

require_relative "base"

module SidekiqAlive
  module Server
    class Rack
      extend Base

      class << self
        def run!
          logger.info("[SidekiqAlive] Starting healthcheck '#{server}' server")
          @server_pid = ::Process.fork do
            @handler = handler
            configure_shutdown_signal { @handler.shutdown }

            @handler.run(self, Port: port, Host: host, AccessLog: [], Logger: logger)
          end
          logger.info("[SidekiqAlive] Web server started in subprocess with pid #{@server_pid}")

          self
        end

        def call(env)
          req = ::Rack::Request.new(env)
          if req.path != path
            logger.warn("[SidekiqAlive] Path '#{req.path}' not found")
            [404, {}, ["Not found"]]
          elsif SidekiqAlive.alive?
            logger.debug("[SidekiqAlive] Found alive key!")
            [200, {}, ["Alive!"]]
          else
            response = "Can't find the alive key"
            logger.error("[SidekiqAlive] #{response}")
            [404, {}, [response]]
          end
        rescue StandardError => e
          logger.error("[SidekiqAlive] #{response} looking for alive key. Error: #{e.message}")
          [500, {}, ["Internal Server Error"]]
        end

        private

        def handler
          Helpers.use_rackup? ? ::Rackup::Handler.get(server) : ::Rack::Handler.get(server)
        end

        def server
          SidekiqAlive.config.server
        end
      end
    end
  end
end
