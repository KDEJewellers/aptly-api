require 'socket'
require 'tmpdir'

require_relative 'errors'
require_relative 'representation'

module Aptly
  # Aptly snapshots representation.
  # @see http://www.aptly.info/doc/api/snapshots/
  class Snapshot < Representation
    # Updates a existing {Snapshot}
    # @return {Repository} Updated snapshot description or name
    def update!(**kwords)
      options = kwords
      options = options.map { |k, v| [k.to_s.capitalize, v] }.to_h
      response = connection.send(:put, "/snapshots/#{self.Name}",
                                 body: JSON.generate(options))
      JSON.parse(response.body)
    end

    def show
      response = connection.send(:get, "/snapshots/#{self.Name}")
      JSON.parse(response.body)
    end

    # Delete's a snapshot
    def delete(**kwords)
      response = connection.send(:delete, "/snapshots/#{self.Name}",
                                 query: kwords)
      JSON.parse(response.body)
    end

    class << self
      # List all known snapshots.
      # @param connection [Connection] connection to use for the instance
      # @return [Array<Repository>] all known repositories
      def list(connection = Connection.new, **kwords)
        response = connection.send(:get, '/snapshots', query: kwords)
        JSON.parse(response.body).collect { |r| new(connection, r) }
      end

      # Creates a new {Snapshot}
      # @param name [String] name of the repository
      # @param connection [Connection] connection to use for the instance
      # @return {Repository} newly created instance
      def create(name, connection = Connection.new, **kwords)
        options = kwords
        options = options.map { |k, v| [k.to_s.capitalize, v] }.to_h
        response = connection.send(:post, "/repos/#{name}/snapshots",
                                   body: JSON.generate(options))
        new(connection, JSON.parse(response.body))
      end
    end


  end
end
