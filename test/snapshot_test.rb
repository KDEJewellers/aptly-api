require_relative 'test_helper'

require_relative '../lib/aptly/snapshot'

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
    repo = ::Aptly::Snapshot.new(::Aptly::Connection.new, Name: 'kitten')

    repo.delete

    assert_requested(:delete, 'http://localhost/api/snapshots/kitten')
  end

  def test_snapshot_list
    stub_request(:get, 'http://localhost/api/snapshots')
      .to_return(body: '[{"Name":"snap1","CreatedAt":"2015-02-27T21:36:08.337443295+03:00","Description":"Snapshot from mirror [wheezy-main]: http://mirror.yandex.ru/debian/ wheezy"}]')
    assert_equal ::Aptly::Snapshot.list.size, 1
    assert_equal ::Aptly::Snapshot.list[0].Name, 'snap1'
  end

  def test_snapshot_create
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

    ::Aptly::Snapshot.get('kitten')
    assert_requested(:get, 'http://localhost/api/snapshots/kitten')
  end
end
