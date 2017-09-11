require_relative 'test_helper'

class SnapshotTest < Minitest::Test
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

  def test_snapshot_delete
    stub_request(:delete, 'http://localhost/api/snapshots/kitten')
      .to_return(body: '{}')
    snapshot = ::Aptly::Snapshot.new(::Aptly::Connection.new, Name: 'kitten')

    snapshot.delete

    assert_requested(:delete, 'http://localhost/api/snapshots/kitten')
  end

  def test_snapshot_list
    stub_request(:get, 'http://localhost/api/snapshots')
      .to_return(body: '[{"Name":"snap1","CreatedAt":"2015-02-27T21:36:08.337443295+03:00","Description":"Snapshot from mirror [wheezy-main]: http://mirror.yandex.ru/debian/ wheezy"}]')
    assert_equal ::Aptly::Snapshot.list.size, 1
    assert_equal ::Aptly::Snapshot.list[0].Name, 'snap1'
  end

  def test_snapshot_create
    stub_request(:post, "http://localhost/api/snapshots")
      .with(body: "{\"SourceSnapshots\":\"kitten\",\"Description\":\"Custom\",\"PackageRefs\":[\"Psource pyspi 0.6.1-1.3 3a8b37cbd9a3559e\"],\"Name\":\"snap10\"}")
      .to_return(body: '{"Name":"snap10","CreatedAt":"2015-02-28T20:22:13.312866396+03:00","Description":"Custom"}')

    snapshot = ::Aptly::Snapshot.create('snap10',
                                        SourceSnapshots: 'kitten',
                                        Description: 'Custom',
                                        PackageRefs: ['Psource pyspi 0.6.1-1.3 3a8b37cbd9a3559e'])

    assert_equal('snap10', snapshot.Name)
    assert_equal('Custom', snapshot.Description)
  end

  def test_snapshot_diff
    stub_request(:get, 'http://localhost/api/snapshots/kitten/diff/mouse')
      .to_return(body: '[{"Left":null,"Right":"Pi386 zziplib-bin 0.13.56-1.1 4eb4563dc85bc3b6"},{"Left":null,"Right":"Pi386 zzuf 0.13.svn20100215-4 2abcc80de15e25f8"}]')
    kitten_snapshot = ::Aptly::Snapshot.new(::Aptly::Connection.new, Name: 'kitten')
    mouse_snapshot = ::Aptly::Snapshot.new(::Aptly::Connection.new, Name: 'mouse')
    diff = kitten_snapshot.diff(mouse_snapshot)
    assert_equal(2, diff.size)
  end

  def test_snapshot_update
    stub_request(:put, 'http://localhost/api/snapshots/kitten1')
      .with(body: '{"Name":"kitten2"}')
      .to_return(body: '{"Name":"kitten2","CreatedAt":"2015-02-27T21:36:08.337443295+03:00","Description":"Snapshot from mirror [wheezy-main]: http://mirror.yandex.ru/debian/ wheezy"}')

    snapshot = ::Aptly::Snapshot.new(::Aptly::Connection.new, Name: 'kitten1')
    snapshot.update!(Name: 'kitten2')
    assert_equal('kitten2', snapshot.Name)
  end

  def test_snapshot_show
    stub_request(:get, 'http://localhost/api/snapshots/kitten')
      .to_return(body: '{"Name":"kitten","CreatedAt":"2015-02-27T21:36:08.337443295+03:00","Description":"Snapshot from mirror [wheezy-main]: http://mirror.yandex.ru/debian/ wheezy"}')

    snapshot = ::Aptly::Snapshot.get('kitten')
    assert_equal('kitten', snapshot.Name)
    assert_requested(:get, 'http://localhost/api/snapshots/kitten')
  end

  def test_snapshot_search
    stub_request(:get, "http://localhost/api/snapshots/kitten/packages")
      .to_return(body: '["Pi386 basilisk2 0.9.20120331-2 86c3e67a4743361f","Pi386 gtktrain 0.9b-13 8770e2e7bfb66bad","Pi386 microcode.ctl 1.18~0+nmu2 5974bce6bd6dbc9e"]')

    stub_request(:get, "http://localhost/api/snapshots/kitten/packages?q=Name%20(~%20matlab)")
      .to_return(body: '["Pall matlab-support 0.0.18 c19e7719c5f39ba0","Pall dynare-matlab 4.3.0-2 e0672404f552bd85","Pall matlab-gdf 0.1.2-2 e5d967263b9047e7"]')

    snapshot = ::Aptly::Snapshot.new(::Aptly::Connection.new, Name: 'kitten')
    result = snapshot.packages
    refute_empty(result)

    result = snapshot.packages(q: 'Name (~ matlab)')
    refute_empty(result)
  end

  def test_snapshot_publish
    stub_request(:post, 'http://localhost/api/publish/kewl-repo-name')
      .with(body: "{\"Distribution\":\"distro\",\"Architectures\":[\"source\"],\"Signing\":{\"Skip\":true},\"SourceKind\":\"snapshot\",\"Sources\":[{\"Name\":\"kewl-snapshot-name\"}]}")
      .to_return(body: "{\"Architectures\":[\"source\"],\"Distribution\":\"distro\",\"Label\":\"\",\"Origin\":\"\",\"Prefix\":\"kewl-repo-name\",\"SourceKind\":\"local\",\"Sources\":[{\"Component\":\"main\",\"Name\":\"kitten\"}],\"Storage\":\"\"}\n")

    snapshot = ::Aptly::Snapshot.new(::Aptly::Connection.new, Name: 'kewl-snapshot-name')
    pub = snapshot.publish('kewl-repo-name', Distribution: 'distro', Architectures: %w[source], Signing: { Skip: true })
    assert pub.is_a?(::Aptly::PublishedRepository)
    assert_equal 'distro', pub.Distribution
    assert_equal 'kewl-repo-name', pub.Prefix
    assert_equal %w[source], pub.Architectures
  end

  def test_published_in
    stub_request(:get, 'http://localhost/api/publish')
      .to_return(body: "[{\"Architectures\":[\"all\"],\"Distribution\":\"distro\",\"Label\":\"\",\"Origin\":\"\",\"Prefix\":\"kewl-repo-name\",\"SourceKind\":\"snapshot\",\"Sources\":[{\"Component\":\"main\",\"Name\":\"kitten\"}],\"Storage\":\"\"}]\n")
    repo = ::Aptly::Snapshot.new(::Aptly::Connection.new, Name: 'kitten')

    # returns array
    pubs = repo.published_in
    assert 1, pubs.size
    yielded = false

    # yields with block
    repo.published_in.each { yielded = true }
    assert yielded
  end
end
