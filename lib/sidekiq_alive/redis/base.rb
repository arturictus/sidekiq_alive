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
        SideKiq.redis{ |redis| redis.ttl(...) }
      end
    end
  end
end
