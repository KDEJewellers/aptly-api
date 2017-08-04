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

    # Raised when a Snapshot consists of a unknown source type
    class UnknownSourceTypeError < StandardError; end

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

    # Raised when a publishing prefix contains a slash when it was expected to
    # be in API-safe format.
    # Unfortunately we cannot automatically coerce as the safe format has
    # character overlap with an unsafe format (_ means something in both), so
    # we'll expect the API consumer to only hand us suitable prefixes.
    # https://www.aptly.info/doc/api/publish/
    class InvalidPrefixError < StandardError; end
  end
end
