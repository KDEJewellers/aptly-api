require 'httmultiparty'

require_relative 'error'

module Aptly
  class Connection
    include HTTMultiParty

    # debug_output $stdout

    DEFAULT_QUERY = {}
    HTTP_ACTIONS = %i(get post delete)

    CODE_ERRORS = {
      400 => ClientError,
      401 => UnauthorizedError,
      404 => NotFoundError,
      409 => ConflictError,
      500 => ServerError
    }

    def initialize(**kwords)
      @query = kwords.fetch(:query, DEFAULT_QUERY)
      @connection = self.class

      uri = URI.parse('')
      uri.scheme = 'http'
      uri.host = ::Aptly.configuration.host
      uri.port = ::Aptly.configuration.port
      self.class.base_uri(uri.to_s)
    end

    def method_missing(symbol, *args, **kwords)
      return super(symbol, *args, kwords) unless HTTP_ACTIONS.include?(symbol)

      kwords[:query] = build_query(kwords)
      kwords.delete(:query) if kwords[:query].empty?

      relative_path = args.shift

      if symbol == :post && kwords.include?(:body)
        kwords[:headers] ||= {}
        kwords[:headers].merge!('Content-Type' => 'application/json')
      end

      http_call(symbol, add_api(relative_path), kwords)
    end

    private

    attr_reader :connection

    def build_query(kwords)
      query = @query.merge(kwords.delete(:query) { {} })
      query = query.map { |k, v| [k.to_s.capitalize, v] }.to_h
      query
    end

    def add_api(relative_path)
      "/api#{relative_path}"
    end

    def http_call(symbol, path, kwords)
      response = connection.send(symbol, path, kwords)
      error = CODE_ERRORS.fetch(response.code, nil)
      fail error, response.body if error
      response
    end
  end
end
