RSpec.describe SidekiqAlive::Worker do
  let(:worker_instance) { described_class.new }
  subject(:perform){ worker_instance.perform }

  specify { expect(described_class).to be_retryable(false) }
  specify { expect(described_class).to be_processed_in(SidekiqAlive.queue_with_variant) }

  it 'calls to main methods in SidekiqAlive' do
    expect(Sidekiq::Client).to receive(:enqueue_to_in).with(SidekiqAlive.queue_with_variant,
                                                            SidekiqAlive.time_to_live / 2,
                                                            described_class)
    expect(worker_instance).to receive(:clean_old_queues).once.and_call_original
    expect(SidekiqAlive).to receive(:store_alive_key).once
    n = 0
    expect(SidekiqAlive).to receive(:callback).once.and_return(proc { n = 2 })
    perform
    expect(n).to eq 2
  end

  it 'uses the configured values' do
    SidekiqAlive.setup do |config|
      config.queue_name = "sidekiq_alive"
      config.queue_variant = 'hostname'
    end

    expect(Sidekiq::Client).to receive(:enqueue_to_in).with('sidekiq_alive-hostname',
                                                            SidekiqAlive.time_to_live / 2,
                                                            described_class)
    allow(SidekiqAlive).to receive(:store_alive_key)
    perform
  end

  xdescribe 'clean_old_queues' do

  end
end
