require 'ostruct'

require_relative 'representation'

module Aptly
  # A published repository representation.
  # Published repositories are not {Repository} instances as they are in fact
  # comprised of one or more different repositories.
  # @see http://www.aptly.info/doc/api/publish/
  class PublishedRepository < Representation
    def initialize(*args)
      super(*args)
      self.Sources.collect! { |s| Repository.new(connection, s) }
    end

    # Drops a published repository. This removes the published repository
    # but leaves its soures intact.
    def drop(**kwords)
      connection.send(:delete, "/publish/#{self.Prefix}/#{self.Distribution}",
                      query: kwords)
    end

    # Update this published repository using new contents of Sources
    # @note this possibly mutates the attributes depending on the HTTP response
    def update!(**kwords)
      response = connection.send(:put,
                                 "/publish/#{self.Prefix}/#{self.Distribution}",
                                 body: JSON.generate(kwords))
      marshal_load(JSON.parse(response.body))
    end

    class << self
      def list(connection = Connection.new, **kwords)
        kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
        response = connection.send(:get, '/publish',
                                   query: kwords)
        JSON.parse(response.body).collect { |h| new(connection, h) }
      end
    end
  end
end
