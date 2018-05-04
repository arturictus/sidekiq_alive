RSpec.describe SidekiqAlive do
  it "has a version number" do
    expect(SidekiqAlive::VERSION).not_to be nil
  end

  describe 'setup' do
    it do
      k = described_class
      expect(k.port).to eq 7433
      k.port = 4567
      expect(k.port).to eq 4567

      expect(k.liveness_key).to eq "SIDEKIQ::LIVENESS_PROBE_TIMESTAMP"
      k.liveness_key = 'key'
      expect(k.liveness_key).to eq 'key'

      expect(k.time_to_live).to eq 10 * 60
      k.time_to_live = 2 * 60
      expect(k.time_to_live).to eq 2 * 60

      expect(k.after_storing_key.call()).to eq nil
      k.after_storing_key = proc{ 'hello' }
      expect(k.after_storing_key.call()).to eq 'hello'

      expect(k.before_storing_key.call()).to eq nil
      k.before_storing_key = proc{ 'hello' }
      expect(k.before_storing_key.call()).to eq 'hello'
    end
  end
end
