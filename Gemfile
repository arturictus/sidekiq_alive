# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in sidekiq_alive.gemspec
gemspec

gem "sidekiq", ENV["SIDEKIQ_VERSION_RANGE"] || "< 8"

gem "ruby-lsp", "~> 0.4.1", group: :development
gem "simplecov", require: false, group: :test
gem "simplecov-cobertura"
