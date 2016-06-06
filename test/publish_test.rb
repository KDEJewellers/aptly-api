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
      'Prefix' => 'prefix/kewl-repo-name',
      'SourceKind' => 'local',
      'Sources' => [{ 'Component' => 'main', 'Name' => 'kitten' }],
      'Storage' => ''
    )
  end

  def teardown
    WebMock.allow_net_connect!
  end

  def test_drop
    stub_request(:delete, 'http://localhost/api/publish/prefix_kewl-repo-name/distro')
      .to_return(body: '{}')

    @pub.drop
  end

  def test_update!
    ret_hash = @pub.marshal_dump.dup
    # Change the Label to check if the pub is properly updated
    ret_hash[:Label] = 'lab-eel'
    stub_request(:put, 'http://localhost/api/publish/prefix_kewl-repo-name/distro')
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(body: JSON.generate(ret_hash))

    refute_equal('lab-eel', @pub.Label)
    @pub.update!
    assert_equal('lab-eel', @pub.Label)
  end

  def test_snapshot_kind
    pub = ::Aptly::PublishedRepository.new(
      ::Aptly::Connection.new,
      'Architectures' => ['source'],
      'Distribution' => 'distro',
      'Label' => '',
      'Origin' => '',
      'Prefix' => 'prefix/kewl-repo-name',
      'SourceKind' => 'snapshot',
      'Sources' => [{ 'Component' => 'main', 'Name' => 'kitten' }],
      'Storage' => ''
    )

    assert(pub.Sources[0].is_a?(Aptly::Snapshot))
  end

  def test_unknown_kind
    assert_raises Aptly::Errors::UnknownSourceType do
      ::Aptly::PublishedRepository.new(
        ::Aptly::Connection.new,
        'Architectures' => ['source'],
        'Distribution' => 'distro',
        'Label' => '',
        'Origin' => '',
        'Prefix' => 'prefix/kewl-repo-name',
        'SourceKind' => 'kitten',
        'Sources' => [{ 'Component' => 'main', 'Name' => 'kitten' }],
        'Storage' => ''
      )
    end
  end
end
