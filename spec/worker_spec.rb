RSpec.describe SidekiqAlive::Worker do
  context 'When beeing executed in the same instance' do
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
      expect(described_class).to receive(:perform_in).with(SidekiqAlive.config.delay_between_async_other_host_queue, hostname)
      subject.perform(hostname)
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
