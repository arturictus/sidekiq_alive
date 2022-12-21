# frozen_string_literal: true

module SidekiqAlive
  module Helpers
    class << self
      def sidekiq_7
        Gem.loaded_specs["sidekiq"].version >= Gem::Version.new("7")
      end

      def sidekiq_6
        Gem.loaded_specs["sidekiq"].version >= Gem::Version.new("6") &&
          Gem.loaded_specs["sidekiq"].version < Gem::Version.new("7")
      end

      def sidekiq_5
        Gem.loaded_specs["sidekiq"].version >= Gem::Version.new("5") &&
          Gem.loaded_specs["sidekiq"].version < Gem::Version.new("6")
      end
    end
  end
end
