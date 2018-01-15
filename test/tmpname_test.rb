# Copyright (C) 2018 Harald Sitter <sitter@kde.org>
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

module Aptly
  # NB: this is in the module so it can access TmpName which is private.
  class TmpNameTest < Minitest::Test
    def test_dir
      foobar = 'foobar'
      foobar_size = 6 # performance, don't dynamically compute
      tmpname = TmpName.dir(foobar)
      assert_includes(tmpname, foobar)
      # dirs should not contain dots to not confuse the server
      refute_includes(tmpname, '.')
      # The 2 is entirely arbitrary but should be true in all cases as the
      # tmpname includes a YYYYMMDD timestamp.
      assert(tmpname.size > foobar_size * 2, "tmpname '#{tmpname}' too short")
      # Make sure it's actually random.
      256.times do
        refute_equal(tmpname, TmpName.dir(foobar))
      end
    end
  end
end
