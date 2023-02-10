# frozen_string_literal: true

require_relative "base"

module SidekiqAlive
  module Redis
    # Wrapper for redis client used by sidekiq < 7
    #
    class Client < Base
      def set_ttl(key, time:, ex:)
        redis.set(key, time, ex: ex)
      end

      def set(key, val)
        redis.set(key, val)
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
    end
  end
end
