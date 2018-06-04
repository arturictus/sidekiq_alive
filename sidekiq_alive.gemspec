
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sidekiq_alive/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq_alive"
  spec.version       = SidekiqAlive::VERSION
  spec.authors       = ["Artur Pañach"]
  spec.email         = ["arturictus@gmail.com"]

  spec.summary       = %q{Liveness probe for sidekiq on Kubernetes deployments.}
  spec.description   = %q{SidekiqAlive offers a solution to add liveness probe of a Sidekiq instance.

  How?

  A http server is started and on each requests validates that a liveness key is stored in Redis. If it is there means is working.

  A Sidekiq job is the responsable to storing this key. If Sidekiq stops processing jobs
  this key gets expired by Redis an consequently the http server will return a 500 error.

  This Job is responsible to requeue itself for the next liveness probe.}
  spec.homepage      = "https://github.com/arturictus/sidekiq_alive"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-sidekiq", "~> 3.0"
  spec.add_development_dependency "mock_redis"
  spec.add_development_dependency "pry"
  spec.add_dependency "sidekiq"
end
