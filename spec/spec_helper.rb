# frozen_string_literal: true

require "bundler/setup"
require "sidekiq_alive"
require "rspec-sidekiq"
require "rack/test"
require "debug"

ENV["RACK_ENV"] = "test"
ENV["HOSTNAME"] = "test-hostname"

Sidekiq.logger.level = Logger::ERROR

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  config.before do
    Sidekiq.redis(&:flushall)
    SidekiqAlive.config.set_defaults
  end
end
