# Copyright (C) 2015 Harald Sitter <sitter@kde.org>
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

require 'aptly/client'
require 'aptly/configuration'
require 'aptly/connection'
require 'aptly/files'
require 'aptly/publish'
require 'aptly/repository'
require 'aptly/version'

module Aptly
  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    # 400	prefix/distribution is already used by another published repository
    # 404	source snapshot/repo hasn’t been found
    def publish(sources, prefix = '', source_kind = 'local', connection = Connection.new, **kwords)
      kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
      options = kwords.merge(
        SourceKind: source_kind,
        Sources: sources
      )
      response = connection.send(:post, "/publish/#{prefix}",
                                 body: JSON.generate(options))
    end
  end
end
