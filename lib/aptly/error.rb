module Aptly
  # Default error.
  class Error < StandardError; end

  # Generic HTTP error base.
  class HTTPError < Error; end

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
