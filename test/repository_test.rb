# Copyright (C) 2015-2017 Harald Sitter <sitter@kde.org>
# Copyright (C) 2016 Rohan Garg <rohan@garg.io>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

require_relative 'test_helper'

require 'webrick'

class RepositoryTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!
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
  end

  def test_repo_exist?
    stub_request(:get, 'http://localhost/api/repos/kitten')
      .to_return(body: '{"Name":"kitten","Comment":"","DefaultDistribution":"","DefaultComponent":""}')
    stub_request(:get, 'http://localhost/api/repos/missing-repo')
      .to_return(status: 404)

    assert ::Aptly::Repository.exist?('kitten')
    refute ::Aptly::Repository.exist?('missing-repo')
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
      .with(body: "{\"Name\":\"kitten\"}", headers: { 'Content-Type' => 'application/json' })
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
      .with(headers: {'Content-Type'=>/multipart\/form-data; boundary=-----------RubyMultipartPost.*/})
      .to_return(body: '["Aptly__Repository/kitteh.deb"]')
    stub_request(:post, %r{http://localhost/api/repos/kitten/file/Aptly__Repository-(.*)})
      .to_return(body: "{\"FailedFiles\":[],\"Report\":{\"Warnings\":[],\"Added\":[\"gpgmepp_15.08.2+git20151212.1109+15.04-0_source added\"],\"Removed\":[]}}\n")
    stub_request(:delete, %r{http://localhost/api/files/.+})
      .to_return(body: "{}\n")

    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    report = repo.upload([debfile])

    assert report.is_a?(Array)
    assert_equal 1, report.size
    assert_equal 'gpgmepp_15.08.2+git20151212.1109+15.04-0_source added', report[0]
  end

  def test_upload_timeout
    # This test is ab it far reaching, but we want a fairly high level view for
    # timeouts, to make sure this works for the primary upload method, which is
    # itself fairly high level.

    # We'll run POSTs into a custom webrick server, run on a random port of
    # localhost. Startup of the webrick is synced through a ConditionVariable.
    @start_mutex = Mutex.new
    @start_condition = ConditionVariable.new
    @server = nil
    @start_mutex.lock
    @thread = Thread.start do
      Thread.current.abort_on_exception = true
      # Disable logging
      logger = WEBrick::Log.new(nil, WEBrick::Log::FATAL)
      # Broadcast our conditionvariable upon startup.
      start_callback = proc do
        @start_mutex.synchronize { @start_condition.broadcast }
      end
      @server = WEBrick::HTTPServer.new(BindAddress: 'localhost', Port: 0,
                                        Logger: logger,
                                        AccessLog: [], # disables access logging
                                        StartCallback: start_callback)
      @server.start
    end
    @start_condition.wait(@start_mutex)

    # We'll allow localhost connections so we can talk to our webrick.
    WebMock.disable_net_connect!(allow_localhost: true)
    host_uri = URI("http://localhost:#{@server[:Port]}")

    # Stub some calls we don't care about, these are implicitly called as part
    # of the high level upload methods.
    stub_request(:post, Regexp.new("#{host_uri}/api/repos/kitten/file/Aptly__Repository-(.*)"))
      .to_return(body: "{\"FailedFiles\":[],\"Report\":{\"Warnings\":[],\"Added\":[\"gpgmepp_15.08.2+git20151212.1109+15.04-0_source added\"],\"Removed\":[]}}\n")
    stub_request(:delete, Regexp.new("#{host_uri}/api/files/.+"))
      .to_return(body: "{}\n")

    # The live handler has a 2 second delay built-in (which may be interrupted
    # by a broadcast on shutdown).
    @sleep_mutex = Mutex.new
    @sleep_condition = ConditionVariable.new
    @server.mount_proc '/' do |_, response|
      @sleep_mutex.synchronize do
        @sleep_condition.wait(@sleep_mutex, @sleep_time)
      end
      response.body = '{}' # dud response, so JSON.parse succeeds
    end

    # Standard timeout will be short, our request will time out by default!
    config = Aptly::Configuration.new(uri: host_uri, write_timeout: 2)
    repo = ::Aptly::Repository.new(Aptly::Connection.new(config: config),
                                   Name: 'kitten')

    debfile = File.join(__dir__, 'data', 'kitteh.deb')

    # Times out with our timeout
    @sleep_time = 4
    assert_raises Aptly::Errors::TimeoutError do
      repo.upload([debfile])
    end
  ensure
    WebMock.disable_net_connect!(allow_localhost: false)
    @server.stop if @server
    @thread.kill if @thread # murder the server
    # Wake up all sleeping requests
    @sleep_mutex.synchronize { @sleep_condition.broadcast } if @sleep_mutex
    @thread.join(8)
  end

  def test_erroring_upload
    debfile = File.join(__dir__, 'data', 'kitteh.deb')
    stub_request(:post, %r{http://localhost/api/files/Aptly__Repository-(.*)})
      .with(headers: {'Content-Type'=>/multipart\/form-data; boundary=-----------RubyMultipartPost.*/})
      .to_return(body: '["Aptly__Repository/kitteh.deb"]')
    stub_request(:post, %r{http://localhost/api/repos/kitten/file/Aptly__Repository-(.*)})
      .to_return(body: "{\"FailedFiles\":[\"/home/nci/aptly/upload/brum/kitteh.deb\"],\"Report\":{\"Warnings\":[\"Unable to process /home/nci/aptly/upload/Aptly__Repository-smith-20151217-14879-7cq2c8/gpgmepp_15.08.2+git20151212.1109+15.04.orig.tar.xz: stat /home/nci/aptly/upload/Aptly__Repository-smith-20151217-14879-7cq2c8/gpgmepp_15.08.2+git20151212.1109+15.04.orig.tar.xz: no such file or directory\"],\"Added\":[],\"Removed\":[]}}\n")
    stub_request(:delete, %r{http://localhost/api/files/.+})
      .to_return(body: "{}\n")
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    assert_raises ::Aptly::Errors::RepositoryFileError do
      begin
        repo.upload([debfile])
      rescue ::Aptly::Errors::RepositoryFileError => e
        e.to_s
        raise e
      end
    end
  end

  def test_publish
    stub_request(:post, 'http://localhost/api/publish/kewl-repo-name')
      .with(body: '{"Distribution":"distro","Architectures":["source"],"Signing":{"Skip":true},"SourceKind":"local","Sources":[{"Name":"kitten"}]}')
      .to_return(body: "{\"Architectures\":[\"source\"],\"Distribution\":\"distro\",\"Label\":\"\",\"Origin\":\"\",\"Prefix\":\"kewl-repo-name\",\"SourceKind\":\"local\",\"Sources\":[{\"Component\":\"main\",\"Name\":\"kitten\"}],\"Storage\":\"\"}\n")
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')
    pub = repo.publish('kewl-repo-name', Distribution: 'distro', Architectures: %w[source], Signing: { Skip: true })
    assert pub.is_a?(::Aptly::PublishedRepository)
    assert_equal 'distro', pub.Distribution
    assert_equal 'kewl-repo-name', pub.Prefix
    assert_equal %w[source], pub.Architectures
    ##<HTTParty::Response:0x20094f0 parsed_response=[{"error"=>"unable to initialize GPG signer: looks like there are no keys in gpg, please create one (official manual: http://www.gnupg.org/gph/en/manual.html)", "meta"=>"Operation aborted"}], @response=#<Net::HTTPInternalServerError 500 Internal Server Error readbody=true>, @headers={"content-type"=>["application/json; charset=utf-8"], "date"=>["Mon, 14 Dec 2015 11:37:16 GMT"], "content-length"=>["188"]}>
    ##<HTTParty::Response:0x26585b8 parsed_response=[{"error"=>"unable to publish: unable to guess distribution name, please specify explicitly", "meta"=>"Operation aborted"}], @response=#<Net::HTTPInternalServerError 500 Internal Server Error readbody=true>, @headers={"content-type"=>["application/json; charset=utf-8"], "date"=>["Mon, 14 Dec 2015 11:39:00 GMT"], "content-length"=>["121"]}>
    ##<HTTParty::Response:0x1c98848 parsed_response=[{"error"=>"unable to publish: unable to figure out list of architectures, please supply explicit list", "meta"=>"Operation aborted"}], @response=#<Net::HTTPInternalServerError 500 Internal Server Error readbody=true>, @headers={"content-type"=>["application/json; charset=utf-8"], "date"=>["Mon, 14 Dec 2015 11:41:33 GMT"], "content-length"=>["132"]}>
  end

  def test_published?
    stub_request(:get, 'http://localhost/api/publish')
      .to_return(body: "[{\"Architectures\":[\"all\"],\"Distribution\":\"distro\",\"Label\":\"\",\"Origin\":\"\",\"Prefix\":\"kewl-repo-name\",\"SourceKind\":\"local\",\"Sources\":[{\"Component\":\"main\",\"Name\":\"kitten\"}],\"Storage\":\"\"}]\n")
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    assert repo.published?
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

  def test_published_in_multiple
    fake_listing = [
      {
        'Architectures' => ['all'],
        'Distribution' => 'distro',
        'Label' => '',
        'Origin' => '',
        'Prefix' => 'kewl-repo-name',
        'SourceKind' => 'local',
        'Sources' => [{ 'Component' => 'main', 'Name' => 'kitten' }],
        'Storage' => ''
      },
      {
        'Architectures' => ['all'],
        'Distribution' => 'distro',
        'Label' => '',
        'Origin' => '',
        'Prefix' => 'other-repo-name',
        'SourceKind' => 'local',
        'Sources' => [{ 'Component' => 'main', 'Name' => 'other-repo' }],
        'Storage' => ''
      },
      {
        'Architectures' => ['all'],
        'Distribution' => 'distro',
        'Label' => '',
        'Origin' => '',
        'Prefix' => 'two-source-repo-name',
        'SourceKind' => 'local',
        'Sources' => [{ 'Component' => 'main', 'Name' => 'kitten' },
                      { 'Component' => 'main', 'Name' => 'other-repo' }],
        'Storage' => ''
      }
    ]

    stub_request(:get, 'http://localhost/api/publish')
      .to_return(body: JSON.generate(fake_listing))
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    # returns array
    pubs = repo.published_in
    pubs.sort_by(&:Prefix)
    assert_equal(2, pubs.size)
    assert_equal('kewl-repo-name', pubs[0].Prefix)
    assert_equal('two-source-repo-name', pubs[1].Prefix)
    yielded = false

    # yields with block
    yielded = []
    repo.published_in { |x| yielded << x.Prefix }
    assert_equal(%w[kewl-repo-name two-source-repo-name], yielded.sort)
  end

  def test_packages
    stub_request(:get, 'http://localhost/api/repos/kitten/packages')
      .to_return(body: "[\"Pall kitteh 999:999 66f130f348dc4864\"]\n")
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    packages = repo.packages

    assert_equal 1, packages.size
  end

  def test_packages_query
    # .packages parameters aren't meant to get mangled (upcased) as other
    # parameters would be
    stub_request(:get, 'http://localhost/api/repos/kitten/packages?q=dog')
      .to_return(body: "[]\n")
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    packages = repo.packages(q: 'dog')

    assert_equal(0, packages.size)
    assert_requested(:get, 'http://localhost/api/repos/kitten/packages?q=dog')
  end

  def test_list
    stub_request(:get, 'http://localhost/api/repos')
      .to_return(body: "[{\"Name\":\"kitten\",\"Comment\":\"\",\"DefaultDistribution\":\"\",\"DefaultComponent\":\"\"}]\n")

    list = ::Aptly::Repository.list

    assert_equal(1, list.size)
    assert(list[0].is_a?(::Aptly::Repository))
    assert_equal('kitten', list[0].Name)
  end

  def test_add_package
    stub_request(:post, 'http://localhost/api/repos/kitten/packages')
      .with(body: "{\"PackageRefs\":[\"Pall kitteh 999:999 66f130f348dc4864\"]}",
            headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200)
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    packages = 'Pall kitteh 999:999 66f130f348dc4864'

    repo.add_package(packages) # String
    repo.add_package([packages]) # Array
    repo.add_packages(packages) # Alias

    assert_requested(:post, 'http://localhost/api/repos/kitten/packages',
                     body: "{\"PackageRefs\":[\"Pall kitteh 999:999 66f130f348dc4864\"]}",
                     times: 3)
  end

  def test_delete_package
    stub_request(:delete, 'http://localhost/api/repos/kitten/packages')
      .with(body: "{\"PackageRefs\":[\"Pall kitteh 999:999 66f130f348dc4864\"]}",
            headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200)
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')

    packages = 'Pall kitteh 999:999 66f130f348dc4864'

    repo.delete_package(packages) # String
    repo.delete_package([packages]) # Array
    repo.delete_packages(packages) # Alias

    assert_requested(:delete, 'http://localhost/api/repos/kitten/packages',
                     body: "{\"PackageRefs\":[\"Pall kitteh 999:999 66f130f348dc4864\"]}",
                     times: 3)
  end

  def test_edit
    # {:Name=>"kitten", :Comment=>"", :DefaultDistribution=>"meow", :DefaultComponent=>""}

    stub_request(:get, 'http://localhost/api/repos/kitten')
      .to_return(body: '{"Name":"kitten","Comment":"","DefaultDistribution":"","DefaultComponent":""}')

    stub_request(:put, 'http://localhost/api/repos/kitten')
      .with(body: '{"DefaultDistribution":"meow","Comment":"fancy comment"}')
      .to_return(body: '{"Name":"kitten","Comment":"fancy comment","DefaultDistribution":"meow","DefaultComponent":""}')

    stub_request(:put, 'http://localhost/api/repos/kitten')
      .with(body: '{"Comment":"other comment"}')
      .to_return(body: '{"Name":"kitten","Comment":"other comment","DefaultDistribution":"meow","DefaultComponent":""}')

    repo = ::Aptly::Repository.get('kitten')
    assert_equal('kitten', repo.Name)
    assert_equal('', repo.Comment)
    assert_equal('', repo.DefaultDistribution)
    assert_equal('', repo.DefaultComponent)

    ret = repo.edit!(DefaultDistribution: 'meow', Comment: 'fancy comment')
    assert_equal(repo, ret) # ret == self (actual change)
    assert_equal('kitten', repo.Name)
    assert_equal('fancy comment', repo.Comment)
    assert_equal('meow', repo.DefaultDistribution)
    assert_equal('', repo.DefaultComponent)

    ret = repo.edit!(DefaultDistribution: 'meow', Comment: 'fancy comment')
    assert_nil(ret) # ret == nil (no change)
    assert_equal('kitten', repo.Name)
    assert_equal('fancy comment', repo.Comment)
    assert_equal('meow', repo.DefaultDistribution)
    assert_equal('', repo.DefaultComponent)

    ret = repo.edit!(Comment: 'other comment')
    assert_equal(repo, ret) # ret == self (actual change)
    assert_equal('kitten', repo.Name)
    assert_equal('other comment', repo.Comment)
    assert_equal('meow', repo.DefaultDistribution)
    assert_equal('', repo.DefaultComponent)
  end

  # 0.3 compat where snapshot had no explicit name argument, this will go away
  # come 1.0
  def test_snapshot_kwords_compat
    stub_request(:post, 'http://localhost/api/repos/kitten/snapshots')
      .with(body: '{"Name":"snap9"}')
      .to_return(body: '{"Name":"snap9","CreatedAt":"2015-02-28T19:56:59.137192613+03:00","Description":"Snapshot from local repo [local-repo]: fun repo"}')

    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')
    snapshot = repo.snapshot(Name: 'snap9')
    assert_equal snapshot.Name, 'snap9'
  end

  # new snapshot method takes name as argument.
  def test_snapshot
    stub_request(:post, 'http://localhost/api/repos/kitten/snapshots')
      .with(body: '{"Name":"snap9"}')
      .to_return(body: '{"Name":"snap9","CreatedAt":"2015-02-28T19:56:59.137192613+03:00","Description":"Snapshot from local repo [local-repo]: fun repo"}')

    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'kitten')
    snapshot = repo.snapshot('snap9')
    assert_equal snapshot.Name, 'snap9'

    assert_raises ArgumentError do
      repo.snapshot
    end
  end
end
