# frozen_string_literal: true

module SidekiqAlive
  module Redis
    class Base
      def set(...)
        raise(NotImplementedError)
      end

      def match(key)
        raise(NotImplementedError)
      end

      def delete(key)
        raise(NotImplementedError)
      end

      def ttl(...)
        redis.ttl(...)
      end

      private

      def redis
        Sidekiq.redis { |r| r }
      end
    end
  end
end
