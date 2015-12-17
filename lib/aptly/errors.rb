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
      attr_accessor :failures
      attr_accessor :warnings

      def initialize(failures, warnings, *args)
        super(*args)
        @failures = failures
        @warnings = warnings
      end

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
        def from_hash(hash, *args)
          return nil if hash['FailedFiles'].empty?
          new(hash['FailedFiles'], hash['Report']['Warnings'], *args)
        end
      end
    end
  end
end
