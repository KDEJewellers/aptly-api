module Aptly
  # Configuration.
  class Configuration
    # @!attribute host
    #   @return [String] host name to talk to
    attr_accessor :host

    # @!attribute port
    #   @return [Integer] port to talk to host to on
    attr_accessor :port

    # @!attribute path
    #   @return [String] path to use (defaults to /)
    attr_accessor :path

    # Creates a new instance.
    # @param host see {#host}
    # @param port see {#port}
    def initialize(host: 'localhost', port: 80, path: '/')
      @host = host
      @port = port
      @path = path
    end

    def uri
      # FIXME: maybe we should simply configure a URI instead of configuring
      #   each part?
      uri = URI.parse('')
      uri.scheme = 'http'
      uri.host = host
      uri.port = port
      uri.path = path
      uri
    end
  end
end
