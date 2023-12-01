# frozen_string_literal: true

require_relative "gserver"

module SidekiqAlive
  module Server
    class Default < Gserver
      class << self
        def run!
          @server = new(port, host, path)

          SidekiqAlive.logger.info("Starting SidekiqAlive web server on #{host}:#{port}")
          @server.start

          self
        end

        def shutdown!
          SidekiqAlive.logger.info("Shutting down SidekiqAlive web server")
          @server.stop
        end

        private

        def host
          SidekiqAlive.config.host
        end

        def port
          SidekiqAlive.config.port.to_i
        end

        def path
          SidekiqAlive.config.path
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
        elsif SidekiqAlive.alive?
          res.status = 200
          res.body = "Alive!"
        else
          response = "Can't find the alive key"
          res.status = 404
          res.body = response
          SidekiqAlive.logger.error(response)
        end
      rescue StandardError => e
        response = "Internal Server Error"
        res.status = 500
        res.body = response
        SidekiqAlive.logger.error("[SidekiqAlive] #{response}. Error: #{e.message}")
      end

      private

      attr_reader :path
    end
  end
end
