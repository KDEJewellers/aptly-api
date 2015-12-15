require_relative 'test_helper'

class ConnectionTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!
  end

  def teardown
    WebMock.allow_net_connect!
  end

  def test_http_call
    stub_request(:get, 'http://localhost/api/400')
      .to_return(status: 400, body: "[{\"error\":\"client error\",\"meta\":\"aborted\"}]\n")
    stub_request(:get, 'http://localhost/api/401')
      .to_return(status: 401, body: "[{\"error\":\"not authorized\",\"meta\":\"aborted\"}]\n")
    stub_request(:get, 'http://localhost/api/404')
      .to_return(status: 404, body: "[{\"error\":\"not found\",\"meta\":\"aborted\"}]\n")
    stub_request(:get, 'http://localhost/api/409')
      .to_return(status: 409, body: "[{\"error\":\"conflict\",\"meta\":\"aborted\"}]\n")
    stub_request(:get, 'http://localhost/api/500')
      .to_return(status: 500, body: "[{\"error\":\"server error\",\"meta\":\"aborted\"}]\n")
    connection = ::Aptly::Connection.new

    assert_raises ::Aptly::ClientError do
      connection.send(:http_call, :get, '/api/400', {})
    end
    assert_raises ::Aptly::UnauthorizedError do
      connection.send(:http_call, :get, '/api/401', {})
    end
    assert_raises ::Aptly::NotFoundError do
      connection.send(:http_call, :get, '/api/404', {})
    end
    assert_raises ::Aptly::ConflictError do
      connection.send(:http_call, :get, '/api/409', {})
    end
    assert_raises ::Aptly::ServerError do
      connection.send(:http_call, :get, '/api/500', {})
    end
  end
end
