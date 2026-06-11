require 'ostruct'

RSpec.describe MsGraphRest do
  it 'has a version number' do
    expect(MsGraphRest::VERSION).not_to be_nil
  end

  describe MsGraphRest::Client do
    context 'when resource not found' do
      subject { described_class.new(access_token: 'access_token').connection }

      before {
        allow(subject.conn).to receive(:get).and_raise(Faraday::ResourceNotFound.new("Error"))
      }

      it 'raises error' do
        expect { subject.get('path', {}) }.to raise_error(MsGraphRest::ResourceNotFound)
      end
    end

    context 'with an injected Faraday connection' do
      subject { described_class.new(faraday_connection: faraday).connection }

      let(:faraday) do
        Faraday.new(url: 'https://graph.microsoft.com/v1.0/') do |c|
          c.use Faraday::Response::RaiseError
          c.adapter :test do |stub|
            stub.get('/v1.0/me') { [200, { 'Content-Type' => 'application/json' }, '{"mail":"a@b.c"}'] }
            stub.get('/v1.0/missing') { [404, {}, ''] }
          end
        end
      end

      it 'sends requests through the injected connection' do
        expect(subject.get('me', {})).to eq('mail' => 'a@b.c')
      end

      it 'wraps Faraday errors raised by the injected connection' do
        expect { subject.get('missing', {}) }.to raise_error(MsGraphRest::ResourceNotFound)
      end
    end

    context 'when parsing error' do
      subject { described_class.new(access_token: 'access_token').connection }

      before {
        allow(subject.conn).to receive(:get).and_return(OpenStruct.new(body: '{'))
      }

      it 'raises error' do
        expect { subject.get('path', {}) }.to raise_error(MsGraphRest::ParseError)
      end
    end
  end

  describe '.use_fake' do
    before do
      described_class.use_fake = true
      described_class.fake_folder = "#{__dir__}/fake_client"
    end

    let(:connection) { described_class.new_client(access_token: 'abc').connection }

    it 'works with simple get' do
      result = connection.get('test', {})

      expect(result).to eq('default' => true)
    end

    it 'works with get and parameters' do
      result = connection.get('test_with_params', { 'test1' => 'a', '2' => 'b' })

      expect(result).to eq('test_with_params' => true)
    end

    it 'works with simple post' do
      result = connection.post('simple_post', {})

      expect(result).to eq('simple_post' => true)
    end

    it 'works with post and body' do
      result = connection.post('simple_post', { 'body' => 'test' })

      expect(result).to eq('simple_post_with_body' => true)
    end

    it 'works with missing file' do
      expect do
        connection.patch('missing', { 'body' => 'test' })
      end.to raise_error(Faraday::ClientError) do |error|
        expect(error.response[:body].to_s).to include("No such file or directory")
      end
    end
  end
end
