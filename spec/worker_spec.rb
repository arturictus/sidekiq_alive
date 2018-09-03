RSpec.describe SidekiqAlive::Worker do
  context 'When beeing executed in the same instance' do
    subject do
      described_class.new.tap do |o|
        allow(o).to receive(:hostname_registered?).and_return(true)
        o.perform
      end
    end

    it 'calls to main methods in SidekiqAlive' do
      expect(described_class).to receive(:perform_in)
      expect(SidekiqAlive).to receive(:store_alive_key).once
      expect(SidekiqAlive).to receive(:register_current_instance).once
      n = 0
      expect(SidekiqAlive.config).to receive(:callback).once.and_return(proc { n = 2 })
      subject
      expect(n).to eq 2
    end
  end

  context 'When beeing executed in different instance' do
    let(:hostname) { 'another_instance' }
    subject do
      described_class.new.tap do |o|
        allow(o).to receive(:hostname_registered?).and_return(true)
      end
    end

    it 'requeues itself with hostname input as argument' do

      expect(SidekiqAlive).not_to receive(:store_alive_key)
      expect(SidekiqAlive.config).not_to receive(:callback)
      expect(described_class).to receive(:perform_async).with(hostname)
      subject
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
