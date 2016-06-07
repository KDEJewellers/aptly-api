require_relative 'representation'

module Aptly
  # Aptly snapshots representation.
  # @see http://www.aptly.info/doc/api/snapshots/
  class Snapshot < Representation
    # Updates this snapshot
    # @return [self] if the instance data was mutated
    # @return [nil] if the instance data was not mutated
    def update!(**kwords)
      kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
      response = @connection.send(:put,
                                  "/snapshots/#{self.Name}",
                                  body: JSON.generate(kwords))
      hash = JSON.parse(response.body, symbolize_names: true)
      return nil if hash == marshal_dump
      marshal_load(hash)
      self
    end

    # Delete's this snapshot
    def delete(**kwords)
      connection.send(:delete, "/snapshots/#{self.Name}",
                      query: kwords)
    end

    # Find differences between this and another snapshot
    # @param [Snapshot] to diff against
    # @return [Array<Hash>] diff between the two snashots
    def diff(other_snapshot)
      endpoint = "/snapshots/#{self.Name}/diff/#{other_snapshot.Name}"
      response = @connection.send(:get, endpoint)
      JSON.parse(response.body)
    end

    # Search for a package in this snapshot
    # @return [Array<String>] list of packages found
    def packages(**kwords)
      response = connection.send(:get, "/snapshots/#{self.Name}/packages",
                                 query: kwords,
                                 query_mangle: false)
      JSON.parse(response.body)
    end

    # Convenience wrapper around {Aptly.publish}, publishing this snapshot
    # locally and as only source of prefix.
    # @param prefix [String] prefix to publish under (i.e. published snapshot name)
    # @return [PublishedRepository] newly published repository
    def publish(prefix, **kwords)
      Aptly.publish([{ Name: self.Name }], prefix, 'snapshot', kwords)
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

    class << self
      # List all known snapshots.
      # @param connection [Connection] connection to use for the instance
      # @return [Array<Snapshot>] all known snapshots
      def list(connection = Connection.new, **kwords)
        response = connection.send(:get, '/snapshots', query: kwords)
        JSON.parse(response.body).collect { |r| new(connection, r) }
      end

      # Create a snapshot from package refs
      # @param name [String] name of new snapshot
      # @return [Snapshot] representation of new snapshot
      def create(name, connection = Connection.new, **kwords)
        kwords = kwords.merge(Name: name)
        response = connection.send(:post, '/snapshots',
                                   body: JSON.generate(kwords))
        new(connection, JSON.parse(response.body))
      end

      # Get a snapshot by name
      # @param [String] name of snapshot to get
      # @return [Snapshot] representation of snapshot if snapshot was found
      def get(name, connection = Connection.new)
        response = connection.send(:get, "/snapshots/#{name}")
        new(connection, JSON.parse(response.body))
      end
    end
  end
end
