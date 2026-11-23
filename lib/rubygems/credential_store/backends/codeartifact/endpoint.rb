# frozen_string_literal: true

module Rubygems
  module CredentialStore
    module Backends
      module CodeArtifact
        Endpoint = Data.define(:domain, :owner, :region)

        # A CodeArtifact domain, identified from the account a credential store is asked about.
        class Endpoint
          DOMAIN = /[a-z][a-z0-9-]{0,48}[a-z0-9]/
          OWNER = /[0-9]{12}/
          REGION = /[a-z0-9-]+/
          HOST = /\A(?<domain>#{DOMAIN})-(?<owner>#{OWNER})
                 \.d\.codeartifact\.(?<region>#{REGION})\.(?:amazonaws\.com|on\.aws)\z/x
          ARN = %r{\Aarn:[a-z-]+:codeartifact:(?<region>#{REGION}):(?<owner>#{OWNER}):domain/(?<domain>#{DOMAIN})\z}

          class << self
            def from_arn(arn)
              match = ARN.match(arn)
              return nil unless match

              new(domain: match[:domain], owner: match[:owner], region: match[:region])
            end

            def from_account(service, account)
              url_or_host =
                case service
                when 'bundler' then decode_bundler_key(account)
                when 'rubygems' then account
                end
              # A token sent to a plain http:// source would cross the network unencrypted.
              return nil if url_or_host.nil? || url_or_host.match?(%r{\Ahttp://}i)

              match = HOST.match(host_of(url_or_host))
              return nil unless match

              new(domain: match[:domain], owner: match[:owner], region: match[:region])
            end

            private def decode_bundler_key(key)
              return nil unless key.start_with?('BUNDLE_')

              key.delete_prefix('BUNDLE_').gsub('___', '-').gsub('__', '.').downcase
            end

            private def host_of(url_or_host)
              url_or_host.sub(%r{\Ahttps://}i, '')[%r{\A[^/:?#]*}].downcase
            end
          end
        end
      end
    end
  end
end
