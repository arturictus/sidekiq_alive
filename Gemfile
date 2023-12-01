# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in sidekiq_alive.gemspec
gemspec

gem "sidekiq", ENV["SIDEKIQ_VERSION_RANGE"] || "< 8"

gem "ruby-lsp", "~> 0.5.1", group: :development

group :test do
  gem "simplecov", require: false
  gem "simplecov-cobertura"
  # used for testing compatibility with rack based web server
  gem "webrick", "< 2"
  gem "rack", "< 3"
  gem "rack-test", "~> 2.1.0"
end
