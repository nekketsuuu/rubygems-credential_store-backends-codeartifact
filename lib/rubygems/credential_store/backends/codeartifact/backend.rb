# frozen_string_literal: true

require_relative 'config'
require_relative 'endpoint'
require_relative 'token_fetcher'

module Rubygems
  module CredentialStore
    module Backends
      module CodeArtifact
        # The Gem::CredentialStore backend that answers CodeArtifact hosts with a freshly fetched token.
        class Backend
          SECRET_FORMATS = {
            'bundler' => 'aws:%s',
            'rubygems' => 'Bearer %s'
          }.freeze

          USAGE_HINTS = {
            'bundler' => 'The codeartifact credential store backend only handles CodeArtifact hosts. ' \
                         'Select it per host with `bundle config set credential_store.<host> codeartifact` ' \
                         'so that other hosts can keep using another credential store.',
            'rubygems' => 'The codeartifact credential store backend only handles CodeArtifact hosts. ' \
                          'Select it only when pushing to CodeArtifact, ' \
                          'for example with RUBYGEMS_CREDENTIAL_STORE=codeartifact gem push.'
          }.freeze

          def initialize(config_loader: -> { Config.load }, fetcher: TokenFetcher.new)
            @config_loader = config_loader
            @fetcher = fetcher
            @tokens = {}
          end

          def get(service, account)
            endpoint = Endpoint.from_account(service, account)
            return nil unless endpoint

            format(SECRET_FORMATS.fetch(service), token_for(endpoint))
          end

          # rubocop:disable-next Naming/PredicateMethod -- To match the Gem::CredentialStore backend interface
          def set(service, account, _secret)
            unless Endpoint.from_account(service, account)
              Gem::CredentialStore.warn_once(USAGE_HINTS[service]) if USAGE_HINTS.key?(service)
              return false
            end

            # Returning false would make Bundler write the given token to its config file in plain text.
            Gem::CredentialStore.warn_once 'The codeartifact credential store backend gets a CodeArtifact ' \
                                           'authorization token on demand, so the given credential was not stored.'
            true
          end

          # rubocop:disable-next Naming/PredicateMethod -- To match the Gem::CredentialStore backend interface
          def delete(_service, _account)
            true
          end

          # rubocop:disable-next Naming/PredicateMethod -- To match the Gem::CredentialStore backend interface
          def delete_all(_service)
            true
          end

          private def token_for(endpoint)
            @tokens[endpoint] ||= @fetcher.fetch(endpoint, profile: config.profile_for(endpoint))
          end

          private def config
            @config ||= @config_loader.call
          end
        end
      end
    end
  end
end
