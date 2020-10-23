# Copyright (C) 2015-2020 Harald Sitter <sitter@kde.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

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

  def test_escape_prefix
    assert_equal 'user_lts', ::Aptly.escape_prefix('user/lts')
    assert_equal 'user__lts', ::Aptly.escape_prefix('user_lts')
    assert_equal 'user____lts', ::Aptly.escape_prefix('user__lts')
  end

  def test_repo
    # Tested via RepositoryTest!
  end
end
