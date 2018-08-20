RSpec.describe SidekiqAlive::Worker do
  context 'When beeing execute in the same instance' do
    subject do
      n = described_class.new
      n.perform
    end

    it 'calls to main methods in SidekiqAlive' do
      expect(described_class).to receive(:perform_in)#.with(instance_of(Integer))
      expect(SidekiqAlive).to receive(:store_alive_key).once
      n = 0
      expect(SidekiqAlive.config).to receive(:callback).once.and_return(proc { n = 2 })
      subject
      expect(n).to eq 2
    end
  end
  context 'When beeing executed in different instance' do
    subject do
      n = described_class.new
      n.perform('another_instance')
    end

    it 'requeues itself with hostname input as argument' do
      expect(described_class).to receive(:perform_in)#.with(instance_of(Integer))
      expect(SidekiqAlive).to receive(:store_alive_key).once
      n = 0
      expect(SidekiqAlive.config).to receive(:callback).once.and_return(proc { n = 2 })
      subject
      expect(n).to eq 2
    end
  end
end
