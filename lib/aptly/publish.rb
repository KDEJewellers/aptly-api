require 'ostruct'

module Aptly
  class PublishedRepository < OpenStruct
    attr_accessor :connection
    attr_accessor :data

    def initialize(connection, hash = {})
      @connection = connection
      super(hash)
    end

    def drop(**kwords)
      p connection.send(:delete, "/publish/#{self.Prefix}/#{self.Distribution}",
                      query: kwords)
    end

    class << self
      # 404	directory doesn’t exist
      def list(connection = Connection.new, **kwords)
        kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
        response = connection.send(:get, '/publish',
                                   query: kwords)
        JSON.parse(response.body).collect { |h| new(connection, h) }
      end
    end
  end
end
