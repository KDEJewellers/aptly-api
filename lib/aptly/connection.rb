# Copyright (C) 2015-2017 Harald Sitter <sitter@kde.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

require 'faraday'
require 'json'
require 'uri'

require_relative 'configuration'
require_relative 'errors'

module Aptly
  # Connection adaptor.
  # This class wraps HTTP interactions for our purposes and adds general purpose
  # automation on top of the raw HTTP actions.
  class Connection
    DEFAULT_QUERY = {}.freeze
    private_constant :DEFAULT_QUERY
    GETISH_ACTIONS = %i[get delete].freeze
    private_constant :GETISH_ACTIONS
    POSTISH_ACTIONS = %i[post put].freeze
    private_constant :POSTISH_ACTIONS
    HTTP_ACTIONS = GETISH_ACTIONS + POSTISH_ACTIONS
    WRITE_ACTIONS = (POSTISH_ACTIONS + %i[delete]).freeze
    private_constant :WRITE_ACTIONS

    CODE_ERRORS = {
      400 => Errors::ClientError,
      401 => Errors::UnauthorizedError,
      404 => Errors::NotFoundError,
      409 => Errors::ConflictError,
      500 => Errors::ServerError
    }.freeze
    private_constant :CODE_ERRORS

    # New connection.
    # @param config [Configuration] Configuration instance to use
    # @param query [Hash] Default HTTP query paramaters, these get the
    #   specific query parameters merged upon.
    # @param uri [URI] Base URI for the remote (default from
    #   {Configuration#uri}).
    def initialize(config: ::Aptly.configuration, query: DEFAULT_QUERY,
                   uri: config.uri)
      @query = query
      @base_uri = uri
      raise if faraday_uri.nil?
      @config = config
      @connection = Faraday.new(faraday_uri) do |c|
        c.request :multipart
        c.request :url_encoded
        c.adapter :excon, @adapter_options
      end
    end

    HTTP_ACTIONS.each do |action|
      # private api
      define_method(action) do |relative_path = '', kwords = {}|
        # NB: double splat is broken with Ruby 2.2.1's define_method, so we
        #   cannot splat kwords in the signature.
        kwords[:query] = build_query(kwords)
        kwords.delete(:query) if kwords[:query].empty?

        http_call(action, add_api(relative_path), kwords)
      end
    end

    private

    def faraday_uri
      @adapter_options ||= {}
      @faraday_uri ||= begin
        uri = @base_uri.clone
        return uri unless uri.scheme == 'unix'
        # For Unix domain sockets we need to divide the bits apart as Excon
        # expects the path URI without a socket path and the socket path as
        # option.
        @adapter_options[:socket] = uri.path
        uri.host = nil
        uri
      end
    end

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
        headers['Content-Type'] = 'application/json'
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

    def setup_request(action, request)
      standard_timeout = @config.timeout
      standard_timeout = @config.write_timeout if WRITE_ACTIONS.include?(action)
      request.options.timeout = standard_timeout
    end

    def run_postish(action, path, kwords)
      body = kwords.delete(:body)
      params = kwords.delete(:query)
      headers = kwords.delete(:headers)

      body, headers = mangle_post(body, headers, kwords)

      @connection.send(action, path, body, headers) do |request|
        setup_request(action, request)
        request.params.update(params) if params
      end
    end

    def run_getish(action, path, kwords)
      body = kwords.delete(:body)
      params = kwords.delete(:query)
      headers = kwords.delete(:headers)

      @connection.send(action, path, params, headers) do |request|
        setup_request(action, request)
        if body
          request.headers[:content_type] = 'application/json'
          request.body = body
        end
      end
    end

    def handle_error(response)
      error = CODE_ERRORS.fetch(response.status, nil)
      raise error, response.body if error
      response
    end

    def http_call(action, path, kwords)
      if POSTISH_ACTIONS.include?(action)
        response = run_postish(action, path, kwords)
      elsif GETISH_ACTIONS.include?(action)
        response = run_getish(action, path, kwords)
      else
        raise "Unknown http action: #{action}"
      end
      handle_error(response)
    rescue Faraday::TimeoutError => e
      raise Errors::TimeoutError, e.message
    end
  end
end
