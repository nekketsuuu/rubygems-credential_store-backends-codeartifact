# frozen_string_literal: true

class FakeTokenFetcher
  attr_reader :calls

  def initialize(token: 'token-123', error: nil)
    @token = token
    @error = error
    @calls = []
  end

  def fetch(endpoint, profile:)
    @calls << [endpoint, profile]
    raise @error if @error

    @token
  end
end
