# frozen_string_literal: true

module SidekiqAlive
  module Server
    class << self
      def run!
        server.run!
      end

      private

      def server
        use_rack? ? Rack : Default
      end

      def use_rack?
        return false unless SidekiqAlive.config.server

        require "rack"

        # TODO: Add implementation for rackup (rack version >= 3)
        if Gem.loaded_specs["rack"].version < Gem::Version.new("3")
          true
        else
          logger.warn("Rack server option only supports rack version < 3, using default server")
          false
        end
      rescue LoadError # extra check in case sidekiq removes rack runtime dependency in the future
        logger.warn("Rack is not present in project dependencies, using default server")
        false
      end

      def logger
        SidekiqAlive.logger
      end
    end
  end
end

require_relative "server/default"
require_relative "server/rack"
