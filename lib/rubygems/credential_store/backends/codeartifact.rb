# frozen_string_literal: true

require 'rubygems/credential_store'
require_relative 'codeartifact/version'
require_relative 'codeartifact/backend'

Gem::CredentialStore.register_backend('codeartifact', Rubygems::CredentialStore::Backends::CodeArtifact::Backend.new)
