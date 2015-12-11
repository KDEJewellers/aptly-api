require_relative 'test_helper'

class AptlyConfigurationTest < Minitest::Test
  def test_init
    config = ::Aptly::Configuration.new

    refute_nil config
    refute_nil config.host
    refute_nil config.port
  end

  def test_init_options
    config = ::Aptly::Configuration.new(host: 'localhost', port: 9055)

    refute_nil config
    refute_nil config.host
    refute_nil config.port
  end
end
