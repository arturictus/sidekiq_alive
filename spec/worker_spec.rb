# frozen_string_literal: true

RSpec.describe(SidekiqAlive::Worker) do
  subject(:perform_inline) do
    described_class.perform_inline
  end

  context "When being executed in the same instance" do
    it "stores alive key and requeues it self" do
      SidekiqAlive.register_current_instance
      expect(described_class).to(receive(:perform_in))
      n = 0
      SidekiqAlive.config.callback = proc { n = 2 }
      perform_inline
      expect(n).to(eq(2))
      expect(SidekiqAlive.alive?).to(be(true))
    end
  end

  context "custom liveness probe" do
    it "on error" do
      expect(described_class).not_to(receive(:perform_in))
      n = 0
      SidekiqAlive.config.custom_liveness_probe = proc do
        n = 2
        raise "Nop"
      end
      begin
        perform_inline
      rescue StandardError
        nil
      end
      expect(n).to(eq(2))
      expect(SidekiqAlive.alive?).to(be(false))
    end

    it "on success" do
      expect(described_class).to(receive(:perform_in))
      n = 0
      SidekiqAlive.config.custom_liveness_probe = proc { n = 2 }
      perform_inline

      expect(n).to(eq(2))
      expect(SidekiqAlive.alive?).to(be(true))
    end
  end

  describe "orphaned queues removal" do
    it "removes orphaned queues" do
      queue = instance_double(Sidekiq::Queue, name: "notifications", latency: 10_000, size: 1, clear: nil)
      orphaning_queue = instance_double(Sidekiq::Queue, name: "sidekiq-alive-bar", latency: 200, size: 1, clear: nil)

      orphaned_queue = instance_double(Sidekiq::Queue, name: "sidekiq-alive-foo", latency: 350, size: 1, clear: nil)
      alive_job = instance_double(Sidekiq::JobRecord, klass: "SidekiqAlive::Worker")
      allow(orphaned_queue).to(receive(:all?).and_yield(alive_job))

      imposter_queue = instance_double(Sidekiq::Queue, name: "sidekiq-aliveness", latency: 10_000, size: 1, clear: nil)
      job = instance_double(Sidekiq::JobRecord, klass: "AlivenessWorker")
      allow(imposter_queue).to(receive(:all?).and_yield(job))

      allow(Sidekiq::Queue).to(receive(:all).and_return([queue, imposter_queue, orphaned_queue, orphaning_queue]))

      perform_inline

      expect(queue).not_to(have_received(:clear))
      expect(imposter_queue).not_to(have_received(:clear))
      expect(orphaned_queue).to(have_received(:clear))
      expect(orphaning_queue).not_to(have_received(:clear))
    end
  end
end
