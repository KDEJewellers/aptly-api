require_relative 'test_helper'

class AptlyTest < Minitest::Test
  def teardown
    ::Aptly.instance_variable_set(:@configuration, nil)
  end

  def test_that_it_has_a_version_number
    refute_nil ::Aptly::VERSION
  end

  def test_configuration
    refute_nil ::Aptly.configure
    assert ::Aptly.configure.is_a?(Aptly::Configuration)
  end

  def test_configuration_block
    ::Aptly.configure do |c|
      c.host = 'localhost'
      c.port = 1234
    end
    assert_equal 'localhost', ::Aptly.configure.host
    assert_equal 1234, ::Aptly.configure.port
  end
end
