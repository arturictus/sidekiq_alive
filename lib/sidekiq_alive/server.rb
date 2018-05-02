module SidekiqAlive
  module Server
    # TODO move to config
    LIVENESS_PORT = 7433
    def self.start
      require 'socket'
      Sidekiq::Logging.logger.info "Starting liveness server on #{LIVENESS_PORT}"
      store_alive_key_at_startup # initial livenessProbe to avoid to kill the instance before it triggers the first liveness

      # Start Server
      Thread.start do
        server = TCPServer.new('0.0.0.0', LIVENESS_PORT)
        loop do
          Thread.start(server.accept) do |socket|
            request = socket.gets # Read the first line of the request (the Request-Line)
            if sidekiq_alive?
              status = "200 OK"
              response = "Alive!\n"
            else
              status = "500 ERROR"
              response = "Sidekiq is not ready: Sidekiq.redis.ping returned #{res.inspect} instead of PONG\n"
              Sidekiq::Logging.logger.error response
            end
            socket.print "HTTP/1.1 #{status}\r\n" +
                             "Content-Type: text/plain\r\n" +
                             "Content-Length: #{response.bytesize}\r\n" +
                             "Connection: close\r\n"
            socket.print "\r\n" # blank line separates the header from the body, as required by the protocol
            socket.print response
            socket.close
          end
        end
      end
    end

    def self.time_threshold
      # TODO move to config
      10.minutes
    end

    def self.liveness_key
      # TODO move to config
      "SIDEKIQ::LIVENESS_PROBE_TIMESTAMP"
    end

    def self.store_alive_key
      ::Sidekiq.redis do |r|
        r.set(liveness_key, Time.now.to_i, { ex: time_threshold.to_i })
      end
      # TODO use after_storing_key
    rescue
      # nop
    end

    def self.store_alive_key_at_startup
      Sidekiq::Logging.logger.info "Writing Startup alive key in redis: #{liveness_key}"
      # TODO run worker unless one already enqueued
      store_alive_key
    end

    def self.sidekiq_alive?
      ::Sidekiq.redis do |r|
        r.ttl(liveness_key) == -2 ? false : true
      end
    rescue
      true
    end
  end
end
