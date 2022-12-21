# frozen_string_literal: true

module SidekiqAlive
  module Helpers
    class << self
      def sidekiq_7
        Gem.loaded_specs["sidekiq"].version >= Gem::Version.new("7")
      end
    end
  end
end
