# frozen_string_literal: true

module FixturePath
  def fixture_path(*names)
    File.join(File.expand_path('../fixtures', __dir__), *names)
  end
end
