require 'net/http'
RSpec.describe SidekiqAlive::Server do
  let(:uri) { URI("http://localhost:#{SidekiqAlive.port}") }
  subject(:response) { Net::HTTP.get_response(uri) }

  it 'accepts requests' do
    expect(response.code).to eq '200'
    expect(response.message).to eq("OK")
    expect(response.body).to match("Alive!")
  end

  it "when key is removed form redis should return error" do
    SidekiqAlive.redis.del(SidekiqAlive.liveness_key)
    expect(response.code).to eq '500'
    expect(response.message).to eq("ERROR")
  end
end
