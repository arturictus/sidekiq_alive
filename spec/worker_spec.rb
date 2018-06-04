RSpec.describe SidekiqAlive::Worker do
  subject do
    n = described_class.new
    n.perform
  end

  specify { expect(described_class).to be_retryable(false) }
  specify { expect(described_class).to be_processed_in(SidekiqAlive.queue_name) }

  it 'calls to main methods in SidekiqAlive' do
    expect(Sidekiq::Client).to receive(:enqueue_to_in).with(SidekiqAlive.queue_name, SidekiqAlive.time_to_live / 2, described_class)
    expect(SidekiqAlive).to receive(:store_alive_key).once
    n = 0
    expect(SidekiqAlive).to receive(:callback).once.and_return(proc { n = 2 })
    subject
    expect(n).to eq 2
  end
end
