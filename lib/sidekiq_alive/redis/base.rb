# frozen_string_literal: true

module SidekiqAlive
  module Redis
    class Base
      def set(key, time:, ex:)
        raise("Implement me")
      end

      def match(key)
        raise("Implement me")
      end

      def delete(key)
        raise("Implement me")
      end

      def ttl(...)
        redis.ttl(...)
      end

      def flushall
        redis.flushall
      end

      private

      def redis
        Sidekiq.redis { |r| r }
      end
    end
  end
end
