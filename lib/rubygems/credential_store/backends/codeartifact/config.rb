# frozen_string_literal: true

require_relative 'endpoint'
require_relative 'error'

module Rubygems
  module CredentialStore
    module Backends
      module CodeArtifact
        # Chooses the AWS profile for each domain from the user's config file.
        class Config
          class << self
            def default_path
              File.join(Gem.config_home, 'rubygems-credential_store-backends-codeartifact', 'config.yml')
            end

            def load(path = default_path)
              return new unless File.exist?(path)

              parse(read(path), path: path)
            end

            def parse(yaml, path:)
              data = deserialize(yaml, path) || {}
              raise Error, "#{path} must contain a mapping" unless data.is_a?(Hash)

              domains = data['domains'] || {}
              unless domains.is_a?(Hash) && domains.values.all?(Hash)
                raise Error, "domains in #{path} must be a mapping of mappings"
              end

              domain_profiles = domains.to_h do |arn, entry|
                endpoint = Endpoint.from_arn(arn.to_s)
                raise Error, "#{arn.inspect} in #{path} is not a CodeArtifact domain ARN" unless endpoint

                [endpoint, entry['profile']]
              end

              new(default_profile: data['profile'], domain_profiles: domain_profiles)
            end

            private def read(path)
              File.read(path)
            rescue SystemCallError => e
              raise Error, "Failed to load #{path}: #{e.message}"
            end

            private def deserialize(yaml, path)
              # Do not use gems so as to avoid conflicts with the version in Gemfile.lock.
              require 'rubygems/yaml_serializer'

              Gem::YAMLSerializer.load(yaml)
            rescue StandardError => e
              raise Error, "Failed to parse #{path}: #{e.message}"
            end
          end

          def initialize(default_profile: nil, domain_profiles: {})
            @default_profile = default_profile
            @domain_profiles = domain_profiles
          end

          def profile_for(endpoint)
            [@domain_profiles[endpoint], @default_profile].map(&:to_s).find { |profile| !profile.empty? }
          end
        end
      end
    end
  end
end
