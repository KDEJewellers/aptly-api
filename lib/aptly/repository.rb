require 'socket'
require 'tmpdir'

require_relative 'errors'
require_relative 'representation'

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
      fail error if error
      hash['Report']['Added']
    end

    # FIXME: needs to support single files
    # Convenience wrapper around {Files.upload} and {#add_file}
    def upload(files)
      prefix = "#{self.class.to_s.tr(':', '_')}-#{Socket.gethostname}-"
      directory = Dir::Tmpname.make_tmpname(prefix, nil)
      Files.upload(files, directory, connection)
      add_file(directory)
    ensure
      # FIXME: delete dir?
    end

    # List all packages in the repository
    # @return [Array<String>] list of packages in the repository
    def packages(**kwords)
      response = connection.send(:get, "/repos/#{self.Name}/packages",
                                 query: kwords)
      JSON.parse(response.body)
    end

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
        pub.Sources.each do |src|
          next false unless src.Name == self.Name
          yield repo if block_given?
          true
        end
      end
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
    end
  end
end
