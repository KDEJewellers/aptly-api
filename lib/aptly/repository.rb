# Copyright (C) 2015-2018 Harald Sitter <sitter@kde.org>
# Copyright (C) 2016 Rohan Garg <rohan@garg.io>
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

require 'socket'

require_relative 'errors'
require_relative 'representation'
require_relative 'snapshot'
require_relative 'publishable'
require_relative 'tmpname'

module Aptly
  # Aptly repository representation.
  # @see http://www.aptly.info/doc/api/repos/
  class Repository < Representation
    include Publishable

    # Delete this repository.
    # @return [nil] always returns nil
    def delete!(**kwords)
      connection.send(:delete, "/repos/#{self.Name}", query: kwords)
      nil
    end
    # TODO: 1.0 drop delete, it's dangerous as it might as well delete packages
    alias delete delete!

    # Add a previously uploaded file to the Repository.
    # @return [Hash] report data as specified in the API.
    # FIXME: this should be called file
    def add_file(path, **kwords)
      response = connection.send(:post, "/repos/#{self.Name}/file/#{path}",
                                 query: kwords)
      hash = JSON.parse(response.body)
      error = Errors::RepositoryFileError.from_hash(hash)
      raise error if error
      hash['Report']['Added']
    end

    # FIXME: needs to support single files
    # Convenience wrapper around {Files.upload}, {#add_file} and {Files.delete}
    def upload(files)
      Files.tmp_upload(files, connection) do |dir|
        add_file(dir)
      end
    end

    # List all packages in the repository
    # @return [Array<String>] list of packages in the repository
    def packages(**kwords)
      response = connection.send(:get, "/repos/#{self.Name}/packages",
                                 query: kwords,
                                 query_mangle: false)
      JSON.parse(response.body)
    end

    # Add a package (by key) to the repository.
    # @param packages [Array<String>, String] a list of package keys or
    #   a single package key to add to the repository. The package key(s)
    #   must already be in the aptly database.
    def add_package(packages, **kwords)
      connection.send(:post, "/repos/#{self.Name}/packages",
                      query: kwords,
                      body: JSON.generate(PackageRefs: [*packages]))
      self
    end
    alias add_packages add_package

    # Deletes a package (by key) from the repository.
    # @param packages [Array<String>, String] a list of package keys or
    #   a single package key to add to the repository. The package key(s)
    #   must already be in the aptly database.
    def delete_package(packages, **kwords)
      connection.send(:delete, "/repos/#{self.Name}/packages",
                      query: kwords,
                      body: JSON.generate(PackageRefs: [*packages]))
      self
    end
    alias delete_packages delete_package

    # Convenience wrapper around {Aptly.publish}, publishing this repository
    # locally and as only source of prefix.
    # @param prefix [String] prefix to publish under (i.e. published repo name)
    # @return [PublishedRepository] newly published repository
    def publish(prefix, **kwords)
      Aptly.publish([{ Name: self.Name }], prefix, 'local', kwords)
    end

    # Edit this repository's attributes as per the parameters.
    # @note this possibly mutates the attributes depending on the HTTP response
    # @return [self] if the instance data was mutated
    # @return [nil] if the instance data was not mutated
    def edit!(**kwords)
      response = connection.send(:put,
                                 "/repos/#{self.Name}",
                                 body: JSON.generate(kwords))
      hash = JSON.parse(response.body, symbolize_names: true)
      return nil if hash == marshal_dump
      marshal_load(hash)
      self
    end

    # Creates a new {Snapshot}
    # @param name [String] name of snapshot
    # @return {Snapshot} newly created instance
    def snapshot(name = nil, **kwords)
      # TODO: 1.0
      if name.nil? && !kwords.key?(:Name)
        # backwards compatible handling allows name to be passed though
        # kwords or the argument. Argument is preferred.
        raise ArgumentError, 'wrong number of arguments (given 0, expected 1)'
      end
      kwords[:Name] = name unless name.nil?
      response = connection.send(:post, "/repos/#{self.Name}/snapshots",
                                 body: JSON.generate(kwords))
      Aptly::Snapshot.new(::Aptly::Connection.new, JSON.parse(response.body))
    end

    class << self
      # Get a {Repository} instance if the repository already exists.
      # @param name [String] name of the repository
      # @param connection [Connection] connection to use for the instance
      # @return {Repository} instance if it exists
      def get(name, connection = Connection.new, **kwords)
        kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
        response = connection.send(:get, "/repos/#{name}",
                                   query: kwords)
        new(connection, JSON.parse(response.body))
      end

      # Creates a new {Repository}
      # @param name [String] name fo the repository
      # @param connection [Connection] connection to use for the instance
      # @return {Repository} newly created instance
      def create(name, connection = Connection.new, **kwords)
        options = kwords.merge(name: name)
        options = options.map { |k, v| [k.to_s.capitalize, v] }.to_h
        response = connection.send(:post, '/repos',
                                   body: JSON.generate(options))
        new(connection, JSON.parse(response.body))
      end

      # Check if a repository exists.
      # @param name [String] the name of the repository which might exist
      # @param connection [Connection] connection to use for the instance
      # @return [Boolean] whether or not the repository exists
      def exist?(name, connection = Connection.new, **kwords)
        get(name, connection, **kwords)
        true
      rescue Aptly::Errors::NotFoundError
        false
      end

      # List all known repositories.
      # @param connection [Connection] connection to use for the instance
      # @return [Array<Repository>] all known repositories
      def list(connection = Connection.new, **kwords)
        response = connection.send(:get, '/repos', query: kwords)
        JSON.parse(response.body).collect { |r| new(connection, r) }
      end
    end
  end
end
