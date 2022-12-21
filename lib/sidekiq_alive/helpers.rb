# frozen_string_literal: true

module SidekiqAlive
  module Helpers
    class << self
      def sidekiq_7
        current_sidekiq_version >= Gem::Version.new("7")
      end

      def sidekiq_6
        current_sidekiq_version >= Gem::Version.new("6") &&
          current_sidekiq_version < Gem::Version.new("7")
      end

      def sidekiq_5
        current_sidekiq_version >= Gem::Version.new("5") &&
          current_sidekiq_version < Gem::Version.new("6")
      end

      private

      def current_sidekiq_version
        Gem.loaded_specs["sidekiq"].version
      end
    end
  end
end
