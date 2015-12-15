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
  end
end
