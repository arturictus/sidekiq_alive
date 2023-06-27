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

      def zadd(set_key, ex, key)
        Sidekiq.redis { |redis| redis.call("ZADD", set_key, ex, key) }
      end

      def zrange(set_key, start, stop)
        Sidekiq.redis { |redis| redis.call("ZRANGE", set_key, start, stop) }
      end

      def zrangebyscore(set_key, min, max)
        Sidekiq.redis { |redis| redis.call("ZRANGEBYSCORE", set_key, min, max) }
      end

      def zrem(set_key, key)
        Sidekiq.redis { |redis| redis.call("ZREM", set_key, key) }
      end

      def delete(key)
        Sidekiq.redis { |redis| redis.call("DEL", key) }
      end
    end
  end
end
