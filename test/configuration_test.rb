require_relative 'test_helper'

class AptlyConfigurationTest < Minitest::Test
  def test_init
    config = ::Aptly::Configuration.new

    refute_nil config
    refute_nil config.host
    refute_nil config.port
    refute_nil config.path
  end

  def test_init_options
    config = ::Aptly::Configuration.new(host: 'otherhost',
                                        port: 9055,
                                        path: '/abc')

    refute_nil(config)
    assert_equal(config.host, 'otherhost')
    assert_equal(config.port, 9055)
    assert_equal(config.path, '/abc')
    assert_equal(config.uri.to_s, 'http://otherhost:9055/abc')
  end
end
