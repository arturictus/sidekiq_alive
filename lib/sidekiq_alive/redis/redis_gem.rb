# frozen_string_literal: true

require_relative "base"

module SidekiqAlive
  module Redis
    # Wrapper for `redis` gem used by sidekiq < 7
    # https://github.com/redis/redis-rb
    class RedisGem < Base
      def set(key, time:, ex:)
        redis.set(key, time, ex: ex)
      end

      def get(key)
        redis.get(key)
      end

      def zadd(set_key, ex, key)
        redis.zadd(set_key, ex, key)
      end

      def zrange(set_key, start, stop)
        redis.zrange(set_key, start, stop)
      end

      def zrangebyscore(set_key, min, max)
        redis.zrangebyscore(set_key, min, max)
      end

      def zrem(set_key, key)
        redis.zrem(set_key, key)
      end

      def delete(key)
        redis.del(key)
      end

      private

      def redis
        Sidekiq.redis { |redis| redis }
      end
    end
  end
end
