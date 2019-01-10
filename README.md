# SidekiqAlive

[![Build Status](https://travis-ci.org/arturictus/sidekiq_alive.svg?branch=master)](https://travis-ci.org/arturictus/sidekiq_alive)
[![Maintainability](https://api.codeclimate.com/v1/badges/35c39124564ffeb0ce4e/maintainability)](https://codeclimate.com/github/arturictus/sidekiq_alive/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/35c39124564ffeb0ce4e/test_coverage)](https://codeclimate.com/github/arturictus/sidekiq_alive/test_coverage)

SidekiqAlive offers a solution to add liveness probe for a Sidekiq instance deployed in Kubernetes.
This library can be used to check sidekiq health outside kubernetes.

__How?__

A http server is started and on each requests validates that a liveness key is stored in Redis. If it is there means is working.

A Sidekiq job is the responsable to storing this key. If Sidekiq stops processing jobs
this key gets expired by Redis an consequently the http server will return a 500 error.

This Job is responsible to requeue itself for the next liveness probe.

Each instance in kubernetes will be checked based on `ENV` variable `HOSTNAME` (kubernetes sets this for each replica/pod).


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq_alive'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq_alive

Run `Sidekiq` with a `sidekiq_alive` queue.

```
sidekiq -q sidekiq_alive
```

or in your config:

_sidekiq.yml_
```yaml
queues:
 - default
 - sidekiq_alive
```

__IMPORTANT:__

Make sure you run a `quiet` every time before you stop the pods [(issue)](https://github.com/arturictus/sidekiq_alive/issues/10). That's not only important for SidekiqAlive it's important that your jobs finish before you stop sidekiq.
Check [recommended kubernetes setup](#kubernetes-setup)

## Usage

SidekiqAlive will start when running `sidekiq` command.


__how to disable?__
You can disabled by setting `ENV` variable `DISABLE_SIDEKIQ_ALIVE`
example:

```
DISABLE_SIDEKIQ_ALIVE=true bundle exec sidekiq
```

### Kubernetes setup

Set `livenessProbe` in your Kubernetes deployment

example with recommended setup:

```yaml
spec:
  containers:
    - name: my_app
      image: my_app:latest
      env:
        - name: RAILS_ENV
          value: production
      command:
        - bundle
        - exec
        - sidekiq
      ports:
        - containerPort: 7433
      livenessProbe:
        httpGet:
          path: /
          port: 7433
        initialDelaySeconds: 80 # app specific. Time your sidekiq takes to start processing.
        timeoutSeconds: 5 # can be much less
      readinessProbe:
        httpGet:
          path: /
          port: 7433
        initialDelaySeconds: 80 # app specific
        timeoutSeconds: 5 # can be much less
      lifecycle:
        preStop:
          exec:
            # SIGTERM triggers a quick exit; gracefully terminate instead
            command: ["bundle", "exec", "sidekiqctl", "quiet"]
  terminationGracePeriodSeconds: 60 # put your longest Job time here plus security time.
```

### Outside kubernetes

It's just up to you how you want to use it.

An example in local would be:

```
bundle exec sidekiq
# let it initialize ...
```

```
curl localhost:7433
#=> Alive!
```

## Options

```ruby
SidekiqAlive.setup do |config|
  # ==> Server port
  # Port to bind the server
  # default: 7433
  #
  #   config.port = 7433

  # ==> Liveness key
  # Key to be stored in Redis as probe of liveness
  # default: "SIDEKIQ::LIVENESS_PROBE_TIMESTAMP"
  #
  #   config.liveness_key = "SIDEKIQ::LIVENESS_PROBE_TIMESTAMP"

  # ==> Time to live
  # Time for the key to be kept by Redis.
  # Here is where you can set de periodicity that the Sidekiq has to probe it is working
  # Time unit: seconds
  # default: 10 * 60 # 10 minutes
  #
  #   config.time_to_live = 10 * 60

  # ==> Callback
  # After the key is stored in redis you can perform anything.
  # For example a webhook or email to notify the team
  # default: proc {}
  #
  #    require 'net/http'
  #    config.callback = proc { Net::HTTP.get("https://status.com/ping") }

  # ==> Preferred Queue
  # Sidekiq Alive will try to enqueue the workers to this queue. If not found
  # will do it to the first available queue.
  # It's a good practice to add a dedicated queue for sidekiq alive. If the queue
  # where sidekiq is processing SidekiqALive gets overloaded and takes
  # longer than the `ttl` to process SidekiqAlive::Worker will become the worst
  # scenario. Sidekiq overloaded and restarting every `ttl` cicle.
  # Add the sidekiq alive queue!!
  #
  # default: :sidekiq_alive
  #
  #    config.preferred_queue = :other
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

Here is a example [rails app](https://github.com/arturictus/sidekiq_alive_example) 
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/arturictus/sidekiq_alive. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
