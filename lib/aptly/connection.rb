require 'faraday'
require 'json'
require 'uri'

require_relative 'errors'

module Aptly
  # Connection adaptor.
  # This class wraps HTTP interactions for our purposes and adds general purpose
  # automation on top of the raw HTTP actions.
  class Connection
    DEFAULT_QUERY = {}
    GETISH_ACTIONS = %i(get delete)
    POSTISH_ACTIONS = %i(post put)
    HTTP_ACTIONS = GETISH_ACTIONS + POSTISH_ACTIONS

    CODE_ERRORS = {
      400 => Errors::ClientError,
      401 => Errors::UnauthorizedError,
      404 => Errors::NotFoundError,
      409 => Errors::ConflictError,
      500 => Errors::ServerError
    }

    def initialize(**kwords)
      @query = kwords.fetch(:query, DEFAULT_QUERY)

      uri = URI.parse('')
      uri.scheme = 'http'
      uri.host = ::Aptly.configuration.host
      uri.port = ::Aptly.configuration.port

      @connection = Faraday.new(url: uri.to_s) do |c|
        c.request :multipart
        c.request :url_encoded
        c.adapter :net_http
      end
    end

    def method_missing(symbol, *args, **kwords)
      return super(symbol, *args, kwords) unless HTTP_ACTIONS.include?(symbol)

      kwords[:query] = build_query(kwords)
      kwords.delete(:query) if kwords[:query].empty?

      relative_path = args.shift
      http_call(symbol, add_api(relative_path), kwords)
    end

    private

    def build_query(kwords)
      query = @query.merge(kwords.delete(:query) { {} })
      if kwords.delete(:query_mangle) { true }
        query = query.map { |k, v| [k.to_s.capitalize, v] }.to_h
      end
      query
    end

    def add_api(relative_path)
      "/api#{relative_path}"
    end

    def mangle_post(body, headers, kwords)
      if body
        headers ||= {}
        headers.merge!('Content-Type' => 'application/json')
      else
        kwords.each do |k, v|
          if k.to_s.start_with?('file_')
            body ||= {}
            body[k] = Faraday::UploadIO.new(v, 'application/binary')
          end
        end
      end
      [body, headers]
    end

    def run_postish(action, path, kwords)
      body = kwords.delete(:body)
      headers = kwords.delete(:headers)

      body, headers = mangle_post(body, headers, kwords)

      @connection.send(action, path, body, headers)
    end

    def run_getish(action, path, kwords)
      params = kwords.delete(:query)
      headers = kwords.delete(:headers)
      @connection.send(action, path, params, headers)
    end

    def http_call(action, path, kwords)
      if POSTISH_ACTIONS.include?(action)
        response = run_postish(action, path, kwords)
      elsif GETISH_ACTIONS.include?(action)
        response = run_getish(action, path, kwords)
      else
        fail "Unknown http action: #{action}"
      end
      error = CODE_ERRORS.fetch(response.status, nil)
      fail error, response.body if error
      response
    end
  end
end
