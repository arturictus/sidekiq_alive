require 'bundler/setup'
require 'sidekiq-alive-next'
require 'rspec-sidekiq'
require 'mock_redis'
require 'rack/test'
require 'pry'

ENV['RACK_ENV'] = 'test'
ENV['HOSTNAME'] = 'test-hostname'
# initialize server

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    SidekiqAlive.redis.flushall
    SidekiqAlive.config.set_defaults
    SidekiqAlive.config.logger = Logger.new(IO::NULL)
  end
end
