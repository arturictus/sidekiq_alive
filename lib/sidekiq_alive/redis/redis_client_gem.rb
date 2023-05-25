# frozen_string_literal: true

require_relative "base"

module SidekiqAlive
  module Redis
    # Wrapper for `redis-client` gem used by `sidekiq` > 7
    # https://github.com/redis-rb/redis-client
    class RedisClientGem < Base
      def set(key, time:, ex:)
        Sidekiq.redis { |redis| redis.call("SET", key, time, ex: ex) }
      end

      def get(key)
        Sidekiq.redis { |redis| redis.call("GET", key) }
      end

      def match(key)
        Sidekiq.redis { |redis| redis.scan("MATCH", key).map { |key| key } }
      end

      def delete(key)
        Sidekiq.redis { |redis| redis.call("DEL", key) }
      end
    end
  end
end
