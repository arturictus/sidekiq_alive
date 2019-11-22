RSpec.describe SidekiqAlive::Worker do
  context 'When being executed in the same instance' do
    subject do
      described_class.new.perform
    end

    it 'stores alive key and requeues it self' do
      SidekiqAlive.register_current_instance
      expect(described_class).to receive(:perform_in)
      n = 0
      SidekiqAlive.config.callback = proc { n = 2 }
      subject
      expect(n).to eq 2
      expect(SidekiqAlive.alive?).to be true
    end
  end

  describe '#hostname_registered?' do
    subject do
      described_class.new
    end

    it 'when instance is not registered' do
      expect(subject.hostname_registered?('any-name')).to be false
    end

    it 'when instance is registered' do
      allow(SidekiqAlive).to receive(:registered_instances).and_return(['SIDEKIQ_KEY:any-name'])
      expect(subject.hostname_registered?('any-name')).to be true
    end
  end
end
