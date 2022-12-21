# frozen_string_literal: true

module SidekiqAlive
  module Helpers
    def sidekiq_7
      Gem.loaded_specs["sidekiq"].version >= Gem::Version.new("7")
    end

    module_function :sidekiq_7
  end
end
