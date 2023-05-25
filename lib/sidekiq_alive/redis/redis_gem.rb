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

      def match(key)
        keys = []
        cursor = 0

        loop do
          cursor, found_keys = redis.scan(cursor, match: key, count: 1000)
          keys += found_keys if found_keys
          break if cursor.to_i == 0
        end
        keys
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
