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

    assert_raises ::Aptly::Errors::ClientError do
      connection.send(:http_call, :get, '/api/400', {})
    end
    assert_raises ::Aptly::Errors::UnauthorizedError do
      connection.send(:http_call, :get, '/api/401', {})
    end
    assert_raises ::Aptly::Errors::NotFoundError do
      connection.send(:http_call, :get, '/api/404', {})
    end
    assert_raises ::Aptly::Errors::ConflictError do
      connection.send(:http_call, :get, '/api/409', {})
    end
    assert_raises ::Aptly::Errors::ServerError do
      connection.send(:http_call, :get, '/api/500', {})
    end
  end

  def test_invalid_action
    connection = ::Aptly::Connection.new

    assert_raises RuntimeError do
      connection.send(:http_call, :yoloaction, nil, nil)
    end
  end

  def test_faraday_options_override
    Faraday.default_connection_options = Faraday::ConnectionOptions.new(timeout: 10)
    connection = ::Aptly::Connection.new
    @faraday_connection = connection.instance_variable_get(:@connection)
    assert_equal(@faraday_connection.options[:timeout], 10)

  ensure
    # Make sure connection options are reset to default at the end of the test
    Faraday.default_connection_options = Faraday::ConnectionOptions.new
  end

  def test_uri_option
    c = ::Aptly::Connection.new(uri: URI::HTTP.build(host: 'otherhost'))
    stub_request(:get, 'http://otherhost/api').to_return(status: 200)
    c.get
  end

  def test_unix
    # webmock is a bit screwed up with sockets but is suitably enough
    # for this test case anyway. Basically the actual request URI is meant to
    # be unix:/api which in webmock ends up being 'http://unix/api', the
    # actual socket is passed as param to Excon. We are not testing this but
    # if the path in webmock is well-formed we'll simply assume our socket
    # actually works :O
    stub_request(:get, 'http://unix/api').to_return(status: 200)
    c = ::Aptly::Connection.new(uri: URI.parse('unix:///tmp/sock'))
    c.get
  end
end
