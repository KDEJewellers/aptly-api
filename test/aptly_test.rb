require_relative 'test_helper'

class AptlyTest < Minitest::Test
  def teardown
    ::Aptly.instance_variable_set(:@configuration, nil)
  end

  def test_that_it_has_a_version_number
    refute_nil ::Aptly::VERSION
  end

  def test_configuration
    refute_nil ::Aptly.configuration
    assert ::Aptly.configuration.is_a?(Aptly::Configuration)
  end

  def test_configuration_block
    ::Aptly.configure do |c|
      c.host = 'localhost'
      c.port = 1234
    end
    assert_equal 'localhost', ::Aptly.configuration.host
    assert_equal 1234, ::Aptly.configuration.port
  end

  def test_publish_with_slashed_prefix
    # catch code 500 we don't want to test publish construction here
    assert_raises Aptly::Errors::InvalidPrefixError do
      ::Aptly.publish([{ Name: 'thingy' }], 'dev/unstable')
    end
  end

  def test_repo
    # Tested via RepositoryTest!
  end
end
