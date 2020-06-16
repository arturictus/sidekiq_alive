# frozen_string_literal: true

require 'sinatra/base'
module SidekiqAlive
  class Server < Sinatra::Base
    set :bind, '0.0.0.0'
    set :port, -> { SidekiqAlive.config.port }
    set :server, -> { SidekiqAlive.config.server }

    get '/' do
      if SidekiqAlive.alive?
        status 200
        body 'Alive!'
      else
        response = "Can't find the alive key"
        SidekiqAlive.logger.error(response)
        status 404
        body response
      end
    end
  end
end
