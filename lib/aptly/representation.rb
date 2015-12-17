module Aptly
  # Base representation class to coerce transactional types into useful
  # objects.
  class Representation < OpenStruct
    # @!attribute connection
    #   @return [Connection] the connection used for instance operations
    attr_accessor :connection

    # Initialize a new representation
    # @param connection [Connection] connection to use for instance operations
    # @param hash [Hash] native hash to represent
    def initialize(connection, hash = {})
      @connection = connection
      super(hash)
    end
  end
end
