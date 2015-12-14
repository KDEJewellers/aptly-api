require_relative 'test_helper'

class RepositoryTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!
    # WebMock.allow_net_connect!
    # ::Aptly.configure do |config|
    #   config.host = 'localhost'
    #   config.port = 9090
    # end
  end

  def teardown
    WebMock.allow_net_connect!
  end

  def test_repo_get
    stub_request(:get, 'http://localhost/api/repos/kitten')
      .to_return(body: '{"Name":"kitten","Comment":"","DefaultDistribution":"","DefaultComponent":""}')

    repo = ::Aptly::Repository.get('kitten')
    assert_equal 'kitten', repo.Name
    assert_equal '', repo.Comment
    assert_equal '', repo.DefaultDistribution
    assert_equal '', repo.DefaultComponent

    assert_requested(:get, 'http://localhost/api/repos/kitten')
  end

  def test_repo_delete
    stub_request(:delete, 'http://localhost/api/repos/kitten')
      .to_return(body: '{}')
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    repo.delete

    assert_requested(:delete, 'http://localhost/api/repos/kitten')
  end

  def test_repo_create
    stub_request(:post, 'http://localhost/api/repos')
      .with(body: "{\"Name\":\"kitten\"}")
      .to_return(body: '{"Name":"kitten","Comment":"","DefaultDistribution":"","DefaultComponent":""}')

    repo = ::Aptly::Repository.create('kitten')
    assert_equal 'kitten', repo.Name
    assert_equal '', repo.Comment
    assert_equal '', repo.DefaultDistribution
    assert_equal '', repo.DefaultComponent

    assert_requested(:post, 'http://localhost/api/repos')
  end

  def test_upload
    debfile = File.join(__dir__, 'data', 'kitteh.deb')
    stub_request(:post, %r{http://localhost/api/files/Aptly__Repository-(.*)})
      .with(headers: {'Content-Type'=>'multipart/form-data; boundary=-----------RubyMultipartPost'})
      .to_return(body: '["Aptly__Repository/kitteh.deb"]')
    stub_request(:post, "http://localhost/api/repos/kitten/file/Aptly__Repository/kitteh.deb")
      .to_return(body: '{}')
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    repo.upload([debfile])

    assert_requested(:post, %r{http://localhost/api/files/Aptly__Repository-(.*)})
    assert_requested(:post, "http://localhost/api/repos/kitten/file/Aptly__Repository/kitteh.deb")
  end

  def test_publish
    stub_request(:post, 'http://localhost/api/publish/kewl-repo-name')
      .with(body: '{"Distribution":"distro","Architectures":["source"],"Signing":{"Skip":true},"SourceKind":"local","Sources":[{"Name":"kitten"}]}')
      .to_return(body: "{\"Architectures\":[\"source\"],\"Distribution\":\"distro\",\"Label\":\"\",\"Origin\":\"\",\"Prefix\":\"kewl-repo-name\",\"SourceKind\":\"local\",\"Sources\":[{\"Component\":\"main\",\"Name\":\"kitten\"}],\"Storage\":\"\"}\n")
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')
    pub = repo.publish('kewl-repo-name', Distribution: 'distro', Architectures: %w(source), Signing: { Skip: true })
    assert pub.is_a?(::Aptly::PublishedRepository)
    assert_equal 'distro', pub.Distribution
    assert_equal 'kewl-repo-name', pub.Prefix
    assert_equal %w(source), pub.Architectures
    ##<HTTParty::Response:0x20094f0 parsed_response=[{"error"=>"unable to initialize GPG signer: looks like there are no keys in gpg, please create one (official manual: http://www.gnupg.org/gph/en/manual.html)", "meta"=>"Operation aborted"}], @response=#<Net::HTTPInternalServerError 500 Internal Server Error readbody=true>, @headers={"content-type"=>["application/json; charset=utf-8"], "date"=>["Mon, 14 Dec 2015 11:37:16 GMT"], "content-length"=>["188"]}>
    ##<HTTParty::Response:0x26585b8 parsed_response=[{"error"=>"unable to publish: unable to guess distribution name, please specify explicitly", "meta"=>"Operation aborted"}], @response=#<Net::HTTPInternalServerError 500 Internal Server Error readbody=true>, @headers={"content-type"=>["application/json; charset=utf-8"], "date"=>["Mon, 14 Dec 2015 11:39:00 GMT"], "content-length"=>["121"]}>
    ##<HTTParty::Response:0x1c98848 parsed_response=[{"error"=>"unable to publish: unable to figure out list of architectures, please supply explicit list", "meta"=>"Operation aborted"}], @response=#<Net::HTTPInternalServerError 500 Internal Server Error readbody=true>, @headers={"content-type"=>["application/json; charset=utf-8"], "date"=>["Mon, 14 Dec 2015 11:41:33 GMT"], "content-length"=>["132"]}>
  end

  def test_published?
    stub_request(:get, 'http://localhost/api/publish')
      .to_return(body: "[{\"Architectures\":[\"all\"],\"Distribution\":\"distro\",\"Label\":\"\",\"Origin\":\"\",\"Prefix\":\"kewl-repo-name\",\"SourceKind\":\"local\",\"Sources\":[{\"Component\":\"main\",\"Name\":\"kitten\"}],\"Storage\":\"\"}]\n")
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    assert repo.published?
    assert_requested(:get, 'http://localhost/api/publish')
  end

  def test_published_in
    stub_request(:get, 'http://localhost/api/publish')
      .to_return(body: "[{\"Architectures\":[\"all\"],\"Distribution\":\"distro\",\"Label\":\"\",\"Origin\":\"\",\"Prefix\":\"kewl-repo-name\",\"SourceKind\":\"local\",\"Sources\":[{\"Component\":\"main\",\"Name\":\"kitten\"}],\"Storage\":\"\"}]\n")
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    # returns array
    pubs = repo.published_in
    assert 1, pubs.size
    yielded = false

    # yields with block
    repo.published_in.each { yielded = true }
    assert yielded
  end
end
