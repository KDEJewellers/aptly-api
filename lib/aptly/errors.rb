module Aptly
  # All aptly errors.
  module Errors
    # Generic HTTP error base.
    class HTTPError < StandardError; end

    # Raised when a request returns code 400.
    class ClientError < HTTPError; end

    # Raised when a request returns code 401.
    class UnauthorizedError < HTTPError; end

    # Raised when a request returns code 404.
    class NotFoundError < HTTPError; end

    # Raised when a request returns code 409.
    class ConflictError < HTTPError; end

    # Raised when a request returns code 500.
    class ServerError < HTTPError; end

    # Raised when a file operation had an error.
    class RepositoryFileError < StandardError
      # @!attribute [r] failures
      #   @return [Array<String>] list of failed files
      attr_accessor :failures

      # @!attribute [r] warnings
      #   @return [Array<String>] warnings from remote (one per file generally)
      attr_accessor :warnings

      # Create a new error instance.
      # @param failures see {#failures}
      # @param warnings see {#warnings}
      # @param args forwarded to super
      def initialize(failures, warnings, *args)
        super(*args)
        @failures = failures
        @warnings = warnings
      end

      # @return [String] (formatted) string representation
      def to_s
        <<-EOF

~~~
  Failed to process:
    #{failures.join("\n    ")}
  Warnings:
    #{warnings.join("\n    ")}
~~~
        EOF
      end

      class << self
        # Construct a new instance from a hash
        # @param hash a file operation repsonse hash
        # @return [RepositoryFileError] new error
        # @return [nil] if error is not applicable (hash has empty FailedFiles
        #   array)
        def from_hash(hash, *args)
          return nil if hash['FailedFiles'].empty?
          new(hash['FailedFiles'], hash['Report']['Warnings'], *args)
        end
      end
    end
  end
end
