# frozen_string_literal: true

require 'rubygems/credential_store/backends/codeartifact'
require_relative 'support/fake_token_fetcher'
require_relative 'support/fixture_path'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FixturePath

  config.after do
    Gem::CredentialStore.reset!
  end
end
