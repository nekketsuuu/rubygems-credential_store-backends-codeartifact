# frozen_string_literal: true

require 'bundler'

RSpec.describe Rubygems::CredentialStore::Backends::CodeArtifact::Endpoint do
  let(:host) { 'my-domain-111122223333.d.codeartifact.us-east-1.amazonaws.com' }
  let(:repository_url) { "https://#{host}/my_domain/ruby/" }
  let(:expected) { described_class.new(domain: 'my-domain', owner: '111122223333', region: 'us-east-1') }

  def bundler_account(key)
    Bundler::Settings.key_for(key)
  end

  def rubygems_account(host)
    Gem::ConfigFile.credential_store_account(host)
  end

  describe '.from_account' do
    it 'parses a Bundler account for a repository URL' do
      expect(described_class.from_account('bundler', bundler_account(repository_url))).to eq(expected)
    end

    it 'parses a Bundler account for a bare host' do
      expect(described_class.from_account('bundler', bundler_account(host))).to eq(expected)
    end

    it 'parses a RubyGems account for a push host' do
      expect(described_class.from_account('rubygems', rubygems_account(repository_url.chomp('/')))).to eq(expected)
    end

    it 'parses a dualstack endpoint' do
      dualstack = 'https://my-domain-111122223333.d.codeartifact.us-east-1.on.aws/my_domain/ruby/'

      expect(described_class.from_account('rubygems', rubygems_account(dualstack))).to eq(expected)
    end

    it 'ignores hosts other than CodeArtifact' do
      expect(described_class.from_account('bundler', bundler_account('https://gems.example.com/'))).to be_nil
      expect(described_class.from_account('rubygems', 'rubygems_api_key')).to be_nil
    end

    it 'ignores a host that only looks like CodeArtifact' do
      lookalike = 'https://my-domain-111122223333.d.codeartifact.us-east-1.amazonaws.com.example.com/my_domain/ruby/'

      expect(described_class.from_account('rubygems', rubygems_account(lookalike))).to be_nil
    end

    it 'ignores plain http URLs' do
      expect(described_class.from_account('bundler', bundler_account("http://#{host}/my_domain/ruby/"))).to be_nil
      expect(described_class.from_account('rubygems', "http://#{host}/my_domain/ruby")).to be_nil
    end

    it 'ignores services it does not know' do
      expect(described_class.from_account('other', repository_url)).to be_nil
    end
  end

  describe '.from_arn' do
    it 'parses a domain ARN' do
      expect(described_class.from_arn('arn:aws:codeartifact:us-east-1:111122223333:domain/my-domain')).to eq(expected)
    end

    it 'ignores the partition' do
      expect(described_class.from_arn('arn:aws-cn:codeartifact:us-east-1:111122223333:domain/my-domain'))
        .to eq(expected)
    end

    it 'rejects ARNs of other resources' do
      expect(described_class.from_arn('arn:aws:codeartifact:us-east-1:111122223333:repository/my-domain/my-repo'))
        .to be_nil
      expect(described_class.from_arn('arn:aws:s3:us-east-1:111122223333:domain/my-domain')).to be_nil
    end

    it 'rejects what is not an ARN' do
      expect(described_class.from_arn('my-domain-111122223333')).to be_nil
    end
  end
end
