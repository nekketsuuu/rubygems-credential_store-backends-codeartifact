# frozen_string_literal: true

require 'bundler'

RSpec.describe Rubygems::CredentialStore::Backends::CodeArtifact::Backend do
  let(:fetcher) { FakeTokenFetcher.new }
  let(:config) { Rubygems::CredentialStore::Backends::CodeArtifact::Config.new(default_profile: 'dev-sso') }
  let(:backend) { described_class.new(config_loader: -> { config }, fetcher: fetcher) }
  let(:repository_url) { 'https://my-domain-111122223333.d.codeartifact.us-east-1.amazonaws.com/my_domain/ruby/' }
  let(:bundler_account) { Bundler::Settings.key_for(repository_url) }
  let(:rubygems_account) { Gem::ConfigFile.credential_store_account(repository_url.chomp('/')) }
  let(:warnings) { [] }

  before do
    Gem::CredentialStore.warn_handler = ->(message) { warnings << message }
  end

  describe '#get' do
    it "returns Bundler's user:password form" do
      expect(backend.get('bundler', bundler_account)).to eq('aws:token-123')
    end

    it 'returns the Authorization header value gem push sends' do
      expect(backend.get('rubygems', rubygems_account)).to eq('Bearer token-123')
    end

    it 'fetches with the profile the config chooses' do
      backend.get('bundler', bundler_account)

      endpoint, profile = fetcher.calls.first
      expect(endpoint).to eq(Rubygems::CredentialStore::Backends::CodeArtifact::Endpoint
                               .new(domain: 'my-domain', owner: '111122223333', region: 'us-east-1'))
      expect(profile).to eq('dev-sso')
    end

    it 'fetches one token per domain within a process' do
      backend.get('bundler', bundler_account)
      backend.get('bundler', Bundler::Settings.key_for(repository_url.sub('ruby', 'other_repo')))
      backend.get('rubygems', rubygems_account)

      expect(fetcher.calls.size).to eq(1)
    end

    it 'returns nil without fetching for other hosts' do
      expect(backend.get('bundler', Bundler::Settings.key_for('https://gems.example.com/'))).to be_nil
      expect(backend.get('rubygems', 'rubygems_api_key')).to be_nil
      expect(fetcher.calls).to be_empty
    end

    it 'makes the credential store report a failed read when the token cannot be fetched' do
      error = Rubygems::CredentialStore::Backends::CodeArtifact::Error.new('could not fetch')
      failing_backend = described_class.new(config_loader: -> { config }, fetcher: FakeTokenFetcher.new(error: error))
      store = Gem::CredentialStore.new(backend: failing_backend, service: 'bundler')

      expect(store.get(bundler_account)).to be_nil
      expect(store.read_failed?(bundler_account)).to be(true)
      expect(warnings).to include(/could not fetch/)
    end
  end

  describe '#set' do
    it 'accepts a CodeArtifact credential without storing it, and says so' do
      expect(backend.set('bundler', bundler_account, 'aws:given-token')).to be(true)
      expect(warnings).to include(/gets a CodeArtifact authorization token on demand/)
      expect(fetcher.calls).to be_empty
    end

    it 'refuses Bundler credentials for other hosts and suggests selecting the backend per host' do
      expect(backend.set('bundler', Bundler::Settings.key_for('https://gems.example.com/'), 'user:pass')).to be(false)
      expect(backend.set('bundler', Bundler::Settings.key_for('gems.example.org'), 'user:pass')).to be(false)
      expect(warnings).to contain_exactly(/credential_store\.<host> codeartifact/)
    end

    it 'refuses RubyGems API keys for other hosts and suggests selecting the backend only for pushes' do
      expect(backend.set('rubygems', 'rubygems_api_key', 'rubygems_0123')).to be(false)
      expect(warnings).to contain_exactly(/RUBYGEMS_CREDENTIAL_STORE=codeartifact gem push/)
    end

    it 'refuses credentials for unknown services without a hint' do
      expect(backend.set('other', 'https://gems.example.com/', 'user:pass')).to be(false)
      expect(warnings).to be_empty
    end
  end

  describe '#delete and #delete_all' do
    it 'report success since nothing is stored' do
      expect(backend.delete('bundler', bundler_account)).to be(true)
      expect(backend.delete_all('bundler')).to be(true)
    end
  end
end
