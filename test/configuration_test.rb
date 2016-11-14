require_relative 'test_helper'

class AptlyConfigurationTest < Minitest::Test
  def test_init
    config = ::Aptly::Configuration.new

    refute_nil config
    refute_nil config.host
    refute_nil config.port
    refute_nil config.path
  end

  def test_init_options # deprecated in favor of uri
    config = ::Aptly::Configuration.new(host: 'otherhost',
                                        port: 9055,
                                        path: '/abc')

    refute_nil(config)
    assert_equal(config.host, 'otherhost')
    assert_equal(config.port, 9055)
    assert_equal(config.path, '/abc')
    assert_equal(config.uri.to_s, 'http://otherhost:9055/abc')
  end

  # partially providing deprecated params should construct a full uri
  params = { host: 'otherhost', port: 9055, path: '/abc' }
  params.each do |key, value|
    define_method("test_fallback_compat_#{key}") do
    config = ::Aptly::Configuration.new(key => value)
    reference_params = { host: 'localhost', port: 80, path: '/' }
    reference_params[key] = value
    reference = URI::HTTP.build(reference_params)
    assert_equal(reference, config.uri)
    end
  end

  def test_init_uri
    uri = URI.parse('https://example.com:123/xyz')
    config = ::Aptly::Configuration.new(uri: uri)
    assert_equal(uri, config.uri)
  end
end
