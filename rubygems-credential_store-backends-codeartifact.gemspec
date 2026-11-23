# frozen_string_literal: true

require_relative 'lib/rubygems/credential_store/backends/codeartifact/version'

Gem::Specification.new do |spec|
  spec.name = 'rubygems-credential_store-backends-codeartifact'
  spec.version = Rubygems::CredentialStore::Backends::CodeArtifact::VERSION
  spec.authors = ['Takuma Ishikawa']
  spec.email = ['nekketsuuu@users.noreply.github.com']

  spec.summary = 'A RubyGems and Bundler credential store backend for AWS CodeArtifact.'
  spec.description = 'Gets AWS CodeArtifact authorization tokens on demand for RubyGems and Bundler.'
  spec.homepage = 'https://github.com/nekketsuuu/rubygems-credential_store-backends-codeartifact'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'
  spec.required_rubygems_version = '>= 4.1.0'
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
