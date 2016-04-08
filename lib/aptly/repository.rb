require 'socket'
require 'tmpdir'

require_relative 'errors'
require_relative 'representation'
require_relative 'snapshot'

module Aptly
  # Aptly repository representation.
  # @see http://www.aptly.info/doc/api/repos/
  class Repository < Representation
    # Delete this repository.
    def delete(**kwords)
      connection.send(:delete, "/repos/#{self.Name}", query: kwords)
    end

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
      prefix = "#{self.class.to_s.tr(':', '_')}-#{Socket.gethostname}-"
      directory = Dir::Tmpname.make_tmpname(prefix, nil)
      Files.upload(files, directory, connection)
      add_file(directory)
    ensure
      Files.delete(directory, connection)
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

    # @return [Boolean]
    def published?
      !published_in.empty?
    end

    # Lists all PublishedRepositories self is published in. Namely self must
    # be a source of the published repository in order for it to appear here.
    # This method always returns an array of affected published repositories.
    # If you use this method with a block it will additionally yield each
    # published repository that would appear in the array, making it a shorthand
    # for {Array#each}.
    # @yieldparam pub [PublishedRepository]
    # @return [Array<PublishedRepository>]
    def published_in
      Aptly::PublishedRepository.list(connection).select do |pub|
        next false unless pub.Sources.any? do |src|
          src.Name == self.Name
        end
        yield pub if block_given?
        true
      end
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
    # @return {Snapshot} newly created instance
    def snapshot(**kwords)
      kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
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
