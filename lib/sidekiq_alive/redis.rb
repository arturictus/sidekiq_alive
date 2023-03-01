# frozen_string_literal: true

module SidekiqAlive
  module Redis
    class << self
      def adapter
        Helpers.sidekiq_7 ? Redis::RedisClientGem.new : Redis::RedisGem.new
      end
    end
  end
end

require_relative "redis/base"
require_relative "redis/redis_client_gem"
require_relative "redis/redis_gem"
