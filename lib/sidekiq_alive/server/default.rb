# frozen_string_literal: true

require_relative "http_server"
require_relative "base"

module SidekiqAlive
  module Server
    class Default < HttpServer
      extend Base

      class << self
        def run!
          logger.info("[SidekiqAlive] Starting default healthcheck server on #{host}:#{port}")
          @server_pid = ::Process.fork do
            @server = new(port, host, path)
            # stop is wrapped in a thread because gserver calls synchrnonize which raises an error
            configure_shutdown_signal { Thread.new { @server.stop } }

            @server.start
            @server.join
          end
          logger.info("[SidekiqAlive] Web server started in subprocess with pid #{@server_pid}")

          self
        end
      end

      def initialize(port, host, path, logger = SidekiqAlive.logger)
        super(self, port, host, logger)

        @path = path
      end

      def request_handler(req, res)
        if req.path != path
          res.status = 404
          res.body = "Not found"
          logger.warn("[SidekiqAlive] Path '#{req.path}' not found")
        elsif SidekiqAlive.alive?
          res.status = 200
          res.body = "Alive!"
          logger.debug("[SidekiqAlive] Found alive key!")
        else
          response = "Can't find the alive key"
          res.status = 404
          res.body = response
          logger.error("[SidekiqAlive] #{response}")
        end
      rescue StandardError => e
        response = "Internal Server Error"
        res.status = 500
        res.body = response
        logger.error("[SidekiqAlive] #{response} looking for alive key. Error: #{e.message}")
      end

      private

      attr_reader :path
    end
  end
end
