RSpec.describe SidekiqAlive::Worker do
  let(:worker_instance) { described_class.new }
  subject(:perform){ worker_instance.perform }

  specify { expect(described_class).to be_retryable(false) }

  it 'calls to main methods in SidekiqAlive' do
    expect(described_class).to receive(:set)
      .with(queue: SidekiqAlive.config.queue_with_variant)
      .and_call_original
    expect(described_class).to receive(:perform_in)
      .with(SidekiqAlive.config.time_to_live / 2)
      .and_call_original

    expect(worker_instance).to receive(:clean_old_queues).once.and_call_original
    expect(SidekiqAlive).to receive(:store_alive_key).once
    n = 0
    expect(SidekiqAlive.config).to receive(:callback).once.and_return(proc { n = 2 })
    perform
    expect(n).to eq 2
  end

  it 'uses the configured values' do
    SidekiqAlive.setup do |config|
      config.queue_name = "sidekiq_alive"
      config.queue_variant = 'hostname'
    end

    expect(described_class).to receive(:set)
      .with(queue: 'sidekiq_alive-hostname')
      .and_call_original
    expect(described_class).to receive(:perform_in)
      .with(SidekiqAlive.config.time_to_live / 2)
      .and_call_original

    allow(SidekiqAlive).to receive(:store_alive_key)
    perform
  end

  describe 'clean_old_queues' do
    subject(:clean_old_queues) { described_class.new.clean_old_queues }

    it 'only cleans queues that match configured value and are over the latency' do
      config = SidekiqAlive.config
      queue_to_clean = instance_double(Sidekiq::Queue, name: config.queue_with_variant, latency: config.time_to_live + 1)
      queue_without_latency = instance_double(Sidekiq::Queue, name: config.queue_with_variant, latency: 0)
      queue_without_matching_name = instance_double(Sidekiq::Queue, name: 'default', latency: config.time_to_live + 1)

      allow(Sidekiq::Queue).to receive(:all) { [ queue_to_clean, queue_without_latency, queue_without_matching_name ] }

      expect(queue_to_clean).to receive(:clear).once
      expect(queue_without_latency).to receive(:clear).never
      expect(queue_without_matching_name).to receive(:clear).never

      clean_old_queues
    end
  end
end
