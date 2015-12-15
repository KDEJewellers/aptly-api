require 'ostruct'

require_relative 'representation'

module Aptly
  # A published repository representation.
  # Published repositories are not {Repository} instances as they are in fact
  # comprised of one or more different repositories.
  class PublishedRepository < Representation
    def initialize(*args)
      super(*args)
      self.Sources.collect! { |s| Repository.new(connection, s) }
    end

    def drop(**kwords)
      p connection.send(:delete, "/publish/#{self.Prefix}/#{self.Distribution}",
                        query: kwords)
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
