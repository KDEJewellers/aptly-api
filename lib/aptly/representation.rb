module Aptly
  # Base representation class to coerce transactional types into useful
  # objects.
  class Representation < OpenStruct
    attr_accessor :connection

    def initialize(connection, hash = {})
      @connection = connection
      super(hash)
    end
  end
end
