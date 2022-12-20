# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Update version"
task :version, :new_version do |_, args|
  version_path = "lib/sidekiq_alive/version.rb"
  new_version = args[:new_version]
  version_file = File.read(version_path)

  version_file.match(/VERSION = "(.*)"/)[1].then do |version|
    File.write(version_path, version_file.gsub(version, new_version))
  end

  sh("bundle install")
  sh("git add #{version_path} Gemfile.lock")
  sh("git commit -m 'Update version to #{new_version}'")
end
