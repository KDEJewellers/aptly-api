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

require 'rubygems/deprecate'

module Aptly
  # Configuration.
  class Configuration
    extend Gem::Deprecate

    # @!attribute uri
    #   Generally any suitable URI is allowed. This can also be a Unix domain
    #   socket which needs to be used in the notation unix:/tmp/sock.
    # @return [URI] the base URI for the API (http://localhost by default)
    attr_accessor :uri

    # @!attribute timeout
    #   The request read timeout in seconds. HTTP connections not responding in
    #   this time limit will raise an error. Note that the server-side API is
    #   currently synchronous so a read request may time out for no better
    #   reason than it not getting a suitable database lock in time, so allowing
    #   for some leeway is recommended here.
    #   https://github.com/smira/aptly/pull/459
    # @return [Integer] read timeout seconds
    attr_accessor :timeout

    # @!attribute write_timeout
    #   The request write timeout in seconds. HTTP connections not responding
    #   in this time limit will raise an error. When pushing data into Aptly
    #   or publishing large repositories this value should be suitably high.
    #   This timeout is used for API calls which we expect to need a write-lock
    #   on the server. Using a value of a couple minutes is recommended if
    #   you have concurrent write requests (multiple uploads from different
    #   sources) or the server performance isn't always assured (slow disk,
    #   load spikes).
    # @return [Integer] write timeout seconds
    attr_accessor :write_timeout

    # rubocop:disable Metrics/ParameterLists So long because of deprecation.

    # Creates a new instance.
    # @param uri see {#uri}
    # @param timeout see {#timeout}
    # @param write_timeout see {#write_timeout}
    # @param host DEPRECATED use uri
    # @param port DEPRECATED use uri
    # @param path DEPRECATED use uri
    def initialize(uri: URI::HTTP.build(host: 'localhost',
                                        port: 80,
                                        path: '/'),
                   timeout: [60, faraday_default_timeout].max,
                   write_timeout: [10 * 60, timeout].max,
                   host: nil, port: nil, path: nil)
      @timeout = timeout
      @write_timeout = write_timeout
      @uri = nil
      @uri = uri unless host || port || path
      return if @uri
      @uri = fallback_uri(host, port, path)
    end
    # rubocop:enable Metrics/ParameterLists

    # @!attribute host
    #   @deprecated use {#uri}
    #   @return [String] host name to talk to

    # @!attribute port
    #   @deprecated use {#uri}
    #   @return [Integer] port to talk to host to on

    # @!attribute path
    #   @deprecated use {#uri}
    #   @return [String] path to use (defaults to /)

    # Fake deprecated attributes and redirect them to @uri
    %i[host port path].each do |uri_attr|
      define_method(uri_attr.to_s) do
        @uri.send(uri_attr)
      end
      deprecate uri_attr, :uri, 2017, 1
      define_method("#{uri_attr}=") do |x|
        # Ruby < 2.3 does not manage to handle string ports, so we need
        # to manually convert to integer.
        @uri.send("#{uri_attr}=", uri_attr == :port ? safe_port(x) : x)
      end
      deprecate "#{uri_attr}=".to_sym, :uri, 2017, 1
    end

    private

    def faraday_default_timeout
      Faraday.default_connection_options[:request][:timeout] || -1
    end

    def safe_port(port)
      port ? port.to_i : port
    end

    def fallback_uri(host, port, path)
      URI::HTTP.build(host: host || 'localhost', port: safe_port(port || 80),
                      path: path || '/')
    end
  end
end
