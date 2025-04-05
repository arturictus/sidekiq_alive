# frozen_string_literal: true

require "semver"

module SidekiqAlive
  # Update app version
  #
  class VersionTask
    include Rake::DSL

    VERSION_FILE = "lib/sidekiq_alive/version.rb"

    def initialize
      add_version_task
    end

    # Add version bump task
    #
    def add_version_task
      desc("Bump application version [major, minor, patch]")
      task(:version, [:semver]) do |_task, args|
        new_version = send(args[:semver]).format("%M.%m.%p").to_s

        update_version(new_version)
        commit_and_tag(new_version)
      end
    end

    private

    # Update version file
    #
    # @param [SemVer] new_version
    # @return [void]
    def update_version(new_version)
      u_version = File.read(VERSION_FILE).gsub(SidekiqAlive::VERSION, new_version)
      File.write(VERSION_FILE, u_version)
    end

    # Commit updated version file and Gemfile.lock
    #
    # @return [void]
    def commit_and_tag(new_version)
      sh("git add #{VERSION_FILE}")
      sh("git commit -m 'Update version to #{new_version}'")
    end

    # Semver of ref from
    #
    # @return [SemVer]
    def semver
      @semver ||= SemVer.parse(SidekiqAlive::VERSION)
    end

    # Increase patch version
    #
    # @return [SemVer]
    def patch
      semver.tap { |ver| ver.patch += 1 }
    end

    # Increase minor version
    #
    # @return [SemVer]
    def minor
      semver.tap do |ver|
        ver.minor += 1
        ver.patch = 0
      end
    end

    # Increase major version
    #
    # @return [SemVer]
    def major
      semver.tap do |ver|
        ver.major += 1
        ver.minor = 0
        ver.patch = 0
      end
    end
  end
end
