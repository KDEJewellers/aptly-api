module Aptly
  # Configuration.
  class Configuration
    # @!attribute host
    #   @return [String] host name to talk to
    attr_accessor :host

    # @!attribute port
    #   @return [Integer] port to talk to host to on
    attr_accessor :port

    # Creates a new instance.
    # @param host see {#host}
    # @param port see {#port}
    def initialize(host: 'localhost', port: 80)
      @host = host
      @port = port
    end
  end
end
