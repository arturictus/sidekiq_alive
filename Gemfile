# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in sidekiq_alive.gemspec
gemspec

gem "sidekiq", ENV["SIDEKIQ_VERSION_RANGE"] || "< 8"

gem "ruby-lsp", "~> 0.15.0", group: :development

group :test do
  gem "simplecov", require: false
  gem "simplecov-cobertura"

  # used for testing rack based server
  gem "rack-test", "~> 2.1.0"
  # rackup is not compatible with sidekiq < 7 due to rack version requirement
  if ENV["WITH_RACKUP"] == "true" && ["7", "8"].any? { |range| ENV["SIDEKIQ_VERSION_RANGE"]&.include?(range) }
    gem "rackup", "~> 2.1.0"
  else
    gem "rack", "< 3"
    gem "webrick", "< 2"
  end
end
