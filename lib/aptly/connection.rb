require 'httmultiparty'

module Aptly
  class Connection
    include HTTMultiParty

    # debug_output $stdout

    DEFAULT_QUERY = {}

    def initialize(**kwords)
      @query = kwords.fetch(:query, DEFAULT_QUERY)
      @connection = self.class

      uri = URI.parse('')
      uri.scheme = 'http'
      uri.host = ::Aptly.configure.host
      uri.port = ::Aptly.configure.port
      self.class.base_uri(uri.to_s)
    end

    def query(params = {})
      @query.update(params)
    end

    def get(relative_path, query: {})
      query = @query.merge(query)
      query = nil if query.empty?
      connection.get(add_api(relative_path), query: query)
    end

    def post(relative_path, query: {}, body: nil)
      query = @query.merge(query)
      query = nil if query.empty?
      connection.post(add_api(relative_path),
                      body: body,
                      query: query,
                      headers: { 'Content-Type' => 'application/json' })
    end

    def delete(relative_path, query: {})
      query = @query.merge(query)
      query = nil if query.empty?
      connection.delete(add_api(relative_path),
                        query: query)
    end

    private

    attr_reader :connection

    def add_api(relative_path)
      "/api#{relative_path}"
    end
  end
end
