module Aptly
  class Configuration
    attr_accessor :host
    attr_accessor :port

    def initialize(host: 'localhost', port: 80)
      @host = host
      @port = port
    end
  end
end
