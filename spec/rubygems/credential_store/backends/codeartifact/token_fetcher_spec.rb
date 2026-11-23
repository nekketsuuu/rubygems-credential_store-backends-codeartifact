# frozen_string_literal: true

require 'json'

RSpec.describe Rubygems::CredentialStore::Backends::CodeArtifact::TokenFetcher do
  let(:error_class) { Rubygems::CredentialStore::Backends::CodeArtifact::Error }
  let(:endpoint) do
    Rubygems::CredentialStore::Backends::CodeArtifact::Endpoint
      .new(domain: 'my-domain', owner: '111122223333', region: 'us-east-1')
  end

  def fetch_with(command, profile: nil)
    stub_const("#{described_class}::COMMAND", fixture_path('bin', command))
    described_class.new.fetch(endpoint, profile: profile)
  end

  it 'asks the aws command for a token for the endpoint' do
    expected_argv = %w[
      codeartifact get-authorization-token
      --domain=my-domain
      --domain-owner=111122223333
      --region=us-east-1
      --query=authorizationToken
      --output=text
    ]

    expect(JSON.parse(fetch_with('aws'))['argv']).to eq(expected_argv)
  end

  it 'passes the profile as a single --profile= argument' do
    invocation = JSON.parse(fetch_with('aws', profile: '--endpoint-url=https://example.com'))

    expect(invocation['argv'].last).to eq('--profile=--endpoint-url=https://example.com')
    expect(invocation['argv']).not_to include('--endpoint-url=https://example.com')
  end

  it 'disables the pager' do
    expect(JSON.parse(fetch_with('aws'))['pager']).to eq('')
  end

  it 'leaves the inherited AWS_PROFILE alone without a profile' do
    original = ENV.fetch('AWS_PROFILE', nil)
    ENV['AWS_PROFILE'] = 'inherited'

    expect(JSON.parse(fetch_with('aws'))['profile']).to eq('inherited')
  ensure
    ENV['AWS_PROFILE'] = original
  end

  it 'raises when the aws command fails' do
    expect { fetch_with('aws-failing') }.to raise_error(error_class) { |error|
      expect(error.message).to include('domain my-domain (owner 111122223333, region us-east-1)',
                                       'exited with status 255',
                                       'may not be installed, or AWS authentication may have failed')
    }
  end

  it 'raises when the aws command is missing' do
    expect { fetch_with('missing-aws') }.to raise_error(error_class, /may not be installed/)
  end
end
