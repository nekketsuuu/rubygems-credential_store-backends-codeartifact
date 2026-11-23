# frozen_string_literal: true

RSpec.describe Rubygems::CredentialStore::Backends::CodeArtifact do
  it 'has a version number' do
    expect(Rubygems::CredentialStore::Backends::CodeArtifact::VERSION).not_to be_nil
  end

  it 'registers itself as the codeartifact backend' do
    expect(Gem::CredentialStore.resolve_backend('codeartifact'))
      .to be_a(Rubygems::CredentialStore::Backends::CodeArtifact::Backend)
  end
end
