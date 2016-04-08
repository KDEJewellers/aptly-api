require_relative 'representation'

module Aptly
  # Aptly snapshots representation.
  # @see http://www.aptly.info/doc/api/snapshots/
  class Snapshot < Representation
    # Updates a existing {Snapshot}
    # @return {Snapshot} Updated snapshot description or name
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

    # Delete's a snapshot
    def delete(**kwords)
      connection.send(:delete, "/snapshots/#{self.Name}",
                      query: kwords)
    end

    class << self
      # List all known snapshots.
      # @param connection [Connection] connection to use for the instance
      # @return [Array<Snapshot>] all known snapshots
      def list(connection = Connection.new, **kwords)
        response = connection.send(:get, '/snapshots', query: kwords)
        JSON.parse(response.body).collect { |r| new(connection, r) }
      end

      # Creates a new {Snapshot}
      # @param repo [String] name of the local repo to snapshot
      # @param connection [Connection] connection to use for the instance
      # @return {Snapshot} newly created instance
      def create_from_repo(repo, connection = Connection.new, **kwords)
        kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
        response = connection.send(:post, "/repos/#{repo}/snapshots",
                                   body: JSON.generate(kwords))
        new(connection, JSON.parse(response.body))
      end

      def create_from_refs(connection = Connection.new, **kwords)
        kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
        response = connection.send(:post, '/snapshots',
                                   body: JSON.generate(kwords))
        new(connection, JSON.parse(response.body))
      end

      def get(name, connection = Connection.new)
        response = connection.send(:get, "/snapshots/#{name}")
        new(connection, JSON.parse(response.body))
      end

      alias show get

      def search(package, connection = Connection.new, **kwords)
        response = connection.send(:get, "/api/snapshots/#{package}/packages",
                                   query: kwords)
        JSON.parse(response.body)
      end

      def diff(snapshot, other_snapshot, connection = Connection.new)
        endpoint = "/api/snapshots/#{snapshot}/diff/#{other_snapshot}"
        response = connection.send(:get, endpoint)
        JSON.parse(response.body)
      end
    end
  end
end
