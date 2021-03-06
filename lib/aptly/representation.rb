# Copyright (C) 2015-2017 Harald Sitter <sitter@kde.org>
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

require 'ostruct'

module Aptly
  # Base representation class to coerce transactional types into useful
  # objects.
  class Representation < OpenStruct
    # @!attribute connection
    #   @return [Connection] the connection used for instance operations
    attr_accessor :connection

    # Initialize a new representation
    # @param connection [Connection] connection to use for instance operations
    # @param hash [Hash] native hash to represent
    def initialize(connection = nil, hash = {})
      # TODO: https://bugs.ruby-lang.org/issues/13358 prevents us from requiring
      #   a connection.
      # Mocha test mocking uses .allocate to mock quackability
      #   e.g. mock.responds_like_instance_of(Aptly::Repository)
      # So we need allocate to work, which it doesn't because of OpenStruct!
      @connection = connection
      super(hash)
    end
  end
end
