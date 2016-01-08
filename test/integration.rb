require 'tmpdir'

require_relative 'test_helper'

class RepositoryTest < Minitest::Test
  def self.test_order; :alpha; end

  def setup
    WebMock.disable!
    ::Aptly.configure do |config|
      config.host = 'localhost'
      config.port = 9942
    end
  end

  def teardown
    ::Aptly.instance_variable_set(:@configuration, nil)
    WebMock.enable!
  end

  def test_aaa_wipe
    Dir.chdir(File.dirname(__dir__)) do
      # FileUtils.rm_r(Dir.glob('fuckdocker/*'), verbose: true)
      # system(*%w(vagrant destroy -f)) || abort
      # system(*%w(vagrant up --provider=docker)) || abort
      # system(*%w(vagrant ssh -- sudo rm -rf '/aptly/*')) || abort
    end
  end

  def test_bbb_repo_create
    repo = ::Aptly::Repository.create('kitten')

    refute_nil repo
    assert 'kitten', repo.Name
  end

  def test_ccc_repo_get
    repo = ::Aptly::Repository.get('kitten')

    refute_nil repo
    assert 'kitten', repo.Name
  end

  def test_ddd_repo_packages
    repo = ::Aptly::Repository.get('kitten')
    packages = repo.packages # No exceptions or nothing
    refute_nil packages
    assert packages.is_a?(Array)
    assert_equal 0, packages.size
  end

  def test_ddd_repo_upload
    debfile = File.join(__dir__, 'data', 'kitteh.deb')
    repo = ::Aptly::Repository.get('kitten')

    repo.upload([debfile])

    packages = repo.packages
    refute_nil packages
    assert_equal 1, packages.size

    assert_equal([], repo.packages(q: 'dog'))
  end

  def test_ccc_repo_not_published
    repo = ::Aptly::Repository.get('kitten')
    refute repo.published?
    assert repo.published_in.empty?
  end

  def test_eee_repo_publish
    repo = ::Aptly::Repository.get('kitten')

    # p repo.publish('kewl-repo-name', Distribution: 'distro', Architectures: %w(source), Signing: { Skip: true })
    pub = repo.publish('kf5', Distribution: 'wily', Architectures: %w(amd64), Signing: { Skip: true })
    assert pub.is_a? ::Aptly::PublishedRepository
    assert_equal 'wily', pub.Distribution
    assert_equal %w(amd64), pub.Architectures
    assert_equal 'kitten', pub.Sources[0].Name

    assert repo.published?
    refute repo.published_in.empty?
  end

  def test_repo_list
    list = ::Aptly::Repository.list

    assert_equal(1, list.size)
    assert(list[0].is_a?(::Aptly::Repository))
    assert_equal('kitten', list[0].Name)
  end

  def test_x
    repo = ::Aptly::Repository.new(::Aptly::Connection.new, Name: 'trull')
    assert_raises ::Aptly::Errors::NotFoundError do
      repo.delete
    end
  end
end

BEGIN {
  if __FILE__ == $PROGRAM_NAME
    require 'erb'
    require 'tmpdir'
    tmpdir = Dir.mktmpdir
    renderer = ERB.new(File.read("#{__dir__}/data/aptly.conf.erb"))
    output = renderer.result(binding)
    config = "#{tmpdir}/config"
    File.write(config, output)
    fd = IO.popen(['aptly', 'api', 'serve',
                   '-listen=:9942',
                   "-config=#{config}"])
    at_exit do
      Process.kill('TERM', fd.pid)
      FileUtils.rm_r(tmpdir)
    end
  end
}
