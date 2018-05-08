# SidekiqAlive

SidekiqAlive offers a solution to add liveness probe for a Sidekiq instance deployed in Kubernetes.

__How?__

A http server is started and on each requests validates that a liveness key is stored in Redis. If it is there means is working.

A Sidekiq job is the responsable to storing this key. If Sidekiq stops processing jobs
this key gets expired by Redis an consequently the http server will return a 500 error.

This Job is responsible to requeue itself for the next liveness probe.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq_alive'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq_alive

## Usage

### start the server

rails example:

`config/initializers/sidekiq.rb`

```ruby
SidekiqAlive..start
```

### Run the job for first time

It should only be run on the first time you deploy the app.
It would reschedule itself.

rails example:
```
$ bundle exec rails console

#=> SidekiqAlive.perform_now
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

## Options

```ruby
SidekiqAlive.setup do |config|
  # ==> Server port
  # port to bind the server
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
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/arturictus/sidekiq_alive. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
