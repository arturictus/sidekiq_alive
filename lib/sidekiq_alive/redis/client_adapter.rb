# frozen_string_literal: true

require_relative "base"

module SidekiqAlive
  module Redis
    # Wrapper for redis client adapter used by sidekiq > 7
    #
    class ClientAdapter < Base
      def set(key, time:, ex:)
        redis.call("SET", key, time, ex: ex)
      end

      def match(key)
        redis.scan("MATCH", key).map { |key| key }
      end

      def delete(key)
        redis.call("DEL", key)
      end
    end
  end
end
