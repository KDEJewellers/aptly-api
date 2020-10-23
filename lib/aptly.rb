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

require 'aptly/configuration'
require 'aptly/connection'
require 'aptly/errors'
require 'aptly/files'
require 'aptly/publish'
require 'aptly/repository'
require 'aptly/version'
require 'aptly/snapshot'
require 'aptly/tmpname'

# Aptly API
module Aptly
  class << self
    # Configures aptly in a block.
    def configure
      yield configuration
    end

    # The global configuration instance.
    def configuration
      @configuration ||= Configuration.new
    end

    # Convenience shorthand for {Repository#get}.
    # @since 0.10.0
    def repo(name, connection = Connection.new, **kwords)
      Repository.get(name, connection, **kwords)
    end

    # Publish 1 or more sources into a public repository prefix.
    # @param sources [Array<Repository>] array of repositories to source
    # @param prefix [String] prefix to publish under (i.e. published repo name).
    #   This must be escaped (see {Aptly.escape_prefix})
    # @see Aptly.escape_prefix
    # @param source_kind [String] the source kind (local or snapshot)
    # @return [PublishedRepository] newly published repository
    def publish(sources, prefix = '', source_kind = 'local',
                connection = Connection.new, **kwords)
      # TODO: 1.0 break compat and invert the assertion to want unescaped
      raise Errors::InvalidPrefixError if prefix.include?('/')
      kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
      options = kwords.merge(
        SourceKind: source_kind,
        Sources: sources
      )
      response = connection.send(:post, "/publish/#{prefix}",
                                 body: JSON.generate(options))
      PublishedRepository.new(connection, JSON.parse(response.body))
    end

    # Translates a pathish prefix (e.g. 'dev/unstable_x') to an API-safe prefix
    # (e.g. 'dev_unstable__x')
    # See prefix format description on https://www.aptly.info/doc/api/publish/
    # @return [String] API-safe prefix notation
    # @since 0.7.0
    def escape_prefix(prefix_path)
      prefix_path.gsub('_', '__').tr('/', '_')
    end
  end
end
