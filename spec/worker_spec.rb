RSpec.describe SidekiqAlive::Worker do
  subject do
    n = described_class.new
    n.perform
  end

  it 'calls to main methods in SidekiqAlive' do
    expect(described_class).to receive(:perform_in)#.with(instance_of(Integer))
    expect(SidekiqAlive).to receive(:store_alive_key).once
    n = 0
    expect(SidekiqAlive).to   receive(:callback).once.and_return(proc { n = 2 })
    subject
    expect(n).to eq 2
  end
end
