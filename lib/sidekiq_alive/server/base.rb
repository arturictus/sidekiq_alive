# frozen_string_literal: true

module SidekiqAlive
  module Server
    module Base
      def shutdown!
        SidekiqAlive.logger.info("Shutting down SidekiqAlive web server")
        Process.kill("TERM", @server_pid) unless @server_pid.nil?
        Process.wait(@server_pid) unless @server_pid.nil?
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

      def logger
        SidekiqAlive.logger
      end

      module_function :host, :port, :path, :logger
    end
  end
end
