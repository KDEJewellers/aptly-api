require 'rubygems/deprecate'

module Aptly
  # Configuration.
  class Configuration
    extend Gem::Deprecate

    # @!attribute uri
    #   Generally any suitable URI is allowed. This can also be a Unix domain
    #   socket which needs to be used in the notation unix:/tmp/sock.
    #   @return [URI] the base URI for the API (http://localhost by default)
    attr_accessor :uri

    # Creates a new instance.
    # @param uri see {#uri}
    # @param host DEPRECATED use uri
    # @param port DEPRECATED use uri
    # @param path DEPRECATED use uri
    def initialize(uri: URI::HTTP.build(host: 'localhost',
                                        port: 80,
                                        path: '/'),
                   host: nil, port: nil, path: nil)
      @uri = nil
      @uri = uri unless host || port || path
      return if @uri
      @uri = fallback_uri(host, port, path)
    end

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

    def safe_port(port)
      port ? port.to_i : port
    end

    def fallback_uri(host, port, path)
      URI::HTTP.build(host: host || 'localhost', port: safe_port(port || 80),
                      path: path || '/')
    end
  end
end
