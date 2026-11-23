# frozen_string_literal: true

RSpec.describe Rubygems::CredentialStore::Backends::CodeArtifact::Config do
  let(:error_class) { Rubygems::CredentialStore::Backends::CodeArtifact::Error }
  let(:endpoint) do
    Rubygems::CredentialStore::Backends::CodeArtifact::Endpoint
      .new(domain: 'my-domain', owner: '111122223333', region: 'us-east-1')
  end

  describe '.default_path' do
    it 'lives under the RubyGems config home' do
      allow(Gem).to receive(:config_home).and_return('/home/user/.config')

      expect(described_class.default_path)
        .to eq('/home/user/.config/rubygems-credential_store-backends-codeartifact/config.yml')
    end
  end

  describe '.load' do
    it 'reads the file' do
      config = described_class.load(fixture_path('config.yml'))

      expect(config.profile_for(endpoint)).to eq('shared-artifacts')
    end

    it 'uses no profile when the file does not exist' do
      config = described_class.load(fixture_path('missing.yml'))

      expect(config.profile_for(endpoint)).to be_nil
    end

    it 'names the file when it cannot be read' do
      directory = fixture_path

      expect { described_class.load(directory) }
        .to raise_error(error_class, /\AFailed to load #{Regexp.escape(directory)}/)
    end
  end

  describe '.parse' do
    it 'accepts nothing but comments' do
      config = described_class.parse("# nothing yet\n", path: 'config.yml')

      expect(config.profile_for(endpoint)).to be_nil
    end

    it 'rejects a document that is not a mapping' do
      expect { described_class.parse("- dev-sso\n", path: 'config.yml') }
        .to raise_error(error_class, /config\.yml must contain a mapping/)
    end

    it 'rejects domains that are not a mapping of mappings' do
      yaml = "domains:\n  \"arn:aws:codeartifact:us-east-1:111122223333:domain/my-domain\": dev-sso\n"

      expect { described_class.parse(yaml, path: 'config.yml') }
        .to raise_error(error_class, /domains in config\.yml must be a mapping of mappings/)
    end

    it 'rejects keys that are not domain ARNs' do
      repository_arn = 'arn:aws:codeartifact:us-east-1:111122223333:repository/my-domain/my-repo'
      yaml = "domains:\n  \"#{repository_arn}\":\n    profile: dev-sso\n"

      expect { described_class.parse(yaml, path: 'config.yml') }.to raise_error(error_class) { |error|
        expect(error.message).to eq("#{repository_arn.inspect} in config.yml is not a CodeArtifact domain ARN")
      }
    end
  end

  describe '#profile_for' do
    let(:yaml) do
      <<~YAML
        profile: dev-sso
        domains:
          "arn:aws:codeartifact:us-east-1:111122223333:domain/my-domain":
            profile: shared-artifacts
          "arn:aws:codeartifact:ap-northeast-1:111122223333:domain/my-domain":
            profile: shared-artifacts-apne1
          "arn:aws:codeartifact:us-east-1:444455556666:domain/other-domain":
            profile: 12345
      YAML
    end

    let(:config) { described_class.parse(yaml, path: 'config.yml') }

    it "prefers the profile of the endpoint's domain" do
      expect(config.profile_for(endpoint)).to eq('shared-artifacts')
    end

    it 'tells apart domains of the same name in different regions' do
      expect(config.profile_for(endpoint.with(region: 'ap-northeast-1'))).to eq('shared-artifacts-apne1')
    end

    it 'falls back to the top-level profile for other domains' do
      expect(config.profile_for(endpoint.with(owner: '999999999999'))).to eq('dev-sso')
      expect(config.profile_for(endpoint.with(region: 'eu-west-1'))).to eq('dev-sso')
    end

    it 'treats a numeric profile name as a string' do
      other = endpoint.with(domain: 'other-domain', owner: '444455556666')

      expect(config.profile_for(other)).to eq('12345')
    end
  end
end
