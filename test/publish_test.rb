require_relative 'test_helper'

class PublishTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!
    @pub = ::Aptly::PublishedRepository.new(
      ::Aptly::Connection.new,
      'Architectures' => ['source'],
      'Distribution' => 'distro',
      'Label' => '',
      'Origin' => '',
      'Prefix' => 'kewl-repo-name',
      'SourceKind' => 'local',
      'Sources' => [{ 'Component' => 'main', 'Name' => 'kitten' }],
      'Storage' => ''
    )
  end

  def teardown
    WebMock.allow_net_connect!
  end

  def test_drop
    stub_request(:delete, 'http://localhost/api/publish/kewl-repo-name/distro')
      .to_return(body: '{}')

    @pub.drop
  end

  def test_update!
    stub_request(:put, 'http://localhost/api/publish/kewl-repo-name/distro')
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(body: JSON.generate(@pub.marshal_dump))

    @pub.update!
  end
end
