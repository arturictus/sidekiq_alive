# frozen_string_literal: true

module SidekiqAlive
  module Server
    module Base
      SHUTDOWN_SIGNAL = "TERM"

      def shutdown!
        SidekiqAlive.logger.info("Shutting down SidekiqAlive web server")
        Process.kill(SHUTDOWN_SIGNAL, @server_pid) unless @server_pid.nil?
        Process.wait(@server_pid) unless @server_pid.nil?
      end

      private

      def configure_shutdown_signal(&block)
        Signal.trap(SHUTDOWN_SIGNAL, &block)
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
    end
  end
end
