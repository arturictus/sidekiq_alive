# frozen_string_literal: true

RSpec.describe(SidekiqAlive::Worker) do
  context "When being executed in the same instance" do
    subject do
      described_class.new.perform
    end

    it "stores alive key and requeues it self" do
      SidekiqAlive.register_current_instance
      expect(described_class).to(receive(:perform_in))
      n = 0
      SidekiqAlive.config.callback = proc { n = 2 }
      subject
      expect(n).to(eq(2))
      expect(SidekiqAlive.alive?).to(be(true))
    end
  end
  context "custom liveness probe" do
    subject do
      described_class.new.perform
    end
    it "on error" do
      expect(described_class).not_to(receive(:perform_in))
      n = 0
      SidekiqAlive.config.custom_liveness_probe = proc do
        n = 2
        raise "Nop"
      end
      begin
        subject
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
      subject

      expect(n).to(eq(2))
      expect(SidekiqAlive.alive?).to(be(true))
    end
  end
end
