# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "sidekiq_alive/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq_alive"
  spec.authors       = ["Andrejs Cunskis", "Artur Pañach"]
  spec.email         = ["andrejs.cunskis@gmail.com", "arturictus@gmail.com"]

  spec.version       = SidekiqAlive::VERSION

  spec.required_ruby_version = Gem::Requirement.new(">= 3.1")

  spec.homepage      = "https://github.com/arturictus/sidekiq_alive"
  spec.summary       = "Liveness probe for sidekiq on Kubernetes deployments."
  spec.license       = "MIT"
  spec.description   = <<~DSC
    SidekiqAlive offers a solution to add liveness probe of a Sidekiq instance.

    How?

    A http server is started and on each requests validates that a liveness key is stored in Redis. If it is there means is working.

    A Sidekiq job is the responsable to storing this key. If Sidekiq stops processing jobs
    this key gets expired by Redis an consequently the http server will return a 500 error.

    This Job is responsible to requeue itself for the next liveness probe.
  DSC

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/releases",
    "documentation_uri" => "#{spec.homepage}/blob/v#{spec.version}/README.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
  }

  spec.files         = Dir["README.md", "lib/**/*"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency("bundler", "> 1.16")
  spec.add_development_dependency("debug", "~> 1.6")
  spec.add_development_dependency("rake", "~> 13.0")
  spec.add_development_dependency("rspec", "~> 3.0")
  spec.add_development_dependency("rspec-sidekiq", "~> 5.0")
  spec.add_development_dependency("rubocop-shopify", "~> 2.10")
  spec.add_development_dependency("solargraph", "~> 0.50.0")

  spec.add_dependency("gserver", "~> 0.0.1")
  spec.add_dependency("sidekiq", ">= 5", "< 8")
end
