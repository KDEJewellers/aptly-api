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

require 'English'

module Aptly
  # Helper to generate temporary names
  module TmpName
    # Generate a random temporary directory name.
    # @param prefix [String] arbitrary prefix string to start the name with
    # @return [String] temporary directory name (only safe characters)
    def self.dir(prefix)
      format('%<prefix>s-%<time>s-%<pid>s-%<tid>s-%<rand>s',
             prefix: prefix,
             # rubocop:disable Style/FormatStringToken
             time: Time.now.strftime('%Y%m%d'),
             # rubocop:enable Style/FormatStringToken
             pid: $PROCESS_ID,
             tid: Thread.current.object_id,
             rand: rand(0x100000000).to_s(36))
    end
  end
  private_constant :TmpName
end
