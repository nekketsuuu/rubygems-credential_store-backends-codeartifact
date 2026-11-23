# frozen_string_literal: true

require 'open3'
require_relative 'error'

module Rubygems
  module CredentialStore
    module Backends
      module CodeArtifact
        # Gets a CodeArtifact authorization token by running the aws command.
        class TokenFetcher
          COMMAND = 'aws'

          def fetch(endpoint, profile:)
            # Not aws-sdk gems, as its gems could conflict with the versions in Gemfile.lock.
            args = arguments(endpoint, profile)
            token, status = Open3.capture2({ 'AWS_PAGER' => '' }, COMMAND, *args, stdin_data: '')
            raise Error, failure_message(endpoint, exit_reason(status)) unless status.success?

            token.strip
          rescue SystemCallError => e
            raise Error, failure_message(endpoint, e.message)
          end

          private def arguments(endpoint, profile)
            options = {
              'domain' => endpoint.domain,
              'domain-owner' => endpoint.owner,
              'region' => endpoint.region,
              'query' => 'authorizationToken',
              'output' => 'text'
            }
            options['profile'] = profile if profile

            ['codeartifact', 'get-authorization-token', *options.map { |name, value| "--#{name}=#{value}" }]
          end

          private def exit_reason(status)
            if status.signaled?
              "#{COMMAND} was terminated by SIG#{Signal.signame(status.termsig)}"
            else
              "#{COMMAND} exited with status #{status.exitstatus}"
            end
          end

          private def failure_message(endpoint, reason)
            "Failed to get a CodeArtifact authorization token for domain #{endpoint.domain} " \
              "(owner #{endpoint.owner}, region #{endpoint.region}) (#{reason}). " \
              "The #{COMMAND} command may not be installed, or AWS authentication may have failed."
          end
        end
      end
    end
  end
end
