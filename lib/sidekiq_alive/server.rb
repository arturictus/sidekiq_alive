module SidekiqAlive
  module Server
    def self.start
      require 'socket'
      Sidekiq::Logging.logger.info "Starting liveness server on #{config.port}"
      store_alive_key # initial livenessProbe to avoid to kill the instance before it triggers the first liveness

      # Start Server
      Thread.start do
        server = TCPServer.new('0.0.0.0', config.port)
        loop do
          Thread.start(server.accept) do |socket|
            request = socket.gets # Read the first line of the request (the Request-Line)
            if config.alive?
              status = "200 OK"
              response = "Alive!\n"
            else
              status = "500 ERROR"
              response = "Looks like sidekiq is not working\n"
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

    def self.config
      SidekiqAlive
    end

    def self.store_alive_key
      Sidekiq::Logging.logger.info "Writing Startup alive key in redis: #{config.liveness_key}"
      # TODO run worker unless one already enqueued
      config.store_alive_key
    end


  end
end
