require_relative 'representation'

module Aptly
  # A published repository representation.
  # Published repositories are not {Repository} instances as they are in fact
  # comprised of one or more different repositories.
  # @see http://www.aptly.info/doc/api/publish/
  class PublishedRepository < Representation
    def initialize(*args)
      super(*args)
      # special case for connection being allowed to be nil
      parse_sources if @connection
    end

    # Drops a published repository. This removes the published repository
    # but leaves its soures intact.
    def drop(**kwords)
      connection.send(:delete, "/publish/#{self.Storage}:#{api_prefix}/#{self.Distribution}",
                      query: kwords)
    end

    # Update this published repository using new contents of Sources
    # @note this possibly mutates the attributes depending on the HTTP response
    # @return [self] if the instance data was mutated
    # @return [nil] if the instance data was not mutated
    def update!(**kwords)
      response = connection.send(:put,
                                 "/publish/#{self.Storage}:#{api_prefix}/#{self.Distribution}",
                                 body: JSON.generate(kwords))
      hash = JSON.parse(response.body, symbolize_names: true)
      return nil if hash == marshal_dump
      marshal_load(hash)
      self
    end

    class << self
      # List all published repositories.
      # @return [Array<PublishedRepository>] list of repositories
      def list(connection = Connection.new, **kwords)
        kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
        response = connection.send(:get, '/publish',
                                   query: kwords)
        JSON.parse(response.body).collect { |h| new(connection, h) }
      end

      # Publish an array of {Repository} to a prefix.
      # @param sources [Array<Repository>] array of repositories to source
      # @param prefix [String] the prefix to publish under (must be escaped see
      #    {.escape_prefix})
      # @return [PublishedRepository] newly published repository
      def from_repositories(repos, prefix, **kwords)
        sources = repos.collect { |x| { Name: x.Name } }
        Aptly.publish(sources, prefix, **kwords)
      end
    end

    private

    # The API style prefix. This is the prefix with the following replacments
    #   _ => __
    #   / => _
    def api_prefix
      ::Aptly.escape_prefix(self.Prefix)
    end

    def parse_sources
      self.Sources.collect! do |s|
        case self.SourceKind
        when 'local'
          Repository.new(connection, s)
        when 'snapshot'
          Snapshot.new(connection, s)
        else
          raise Aptly::Errors::UnknownSourceTypeError
        end
      end
    end
  end
end
