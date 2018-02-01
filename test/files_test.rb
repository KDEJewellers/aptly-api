require_relative 'test_helper'

class FilesTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!
  end

  def teardown
    WebMock.allow_net_connect!
  end

  def test_upload
    file_list = ["yolo/#{__FILE__}"]
    stub_request(:post, 'http://localhost/api/files/yolo')
      .with(headers: {'Content-Type'=>/multipart\/form-data; boundary=-----------RubyMultipartPost.*/})
      .to_return(body: JSON.generate(file_list))

    files = ::Aptly::Files.upload([__FILE__], 'yolo')

    assert_equal file_list, files
    assert_requested(:post, 'http://localhost/api/files/yolo')
  end

  def test_delete
    stub_request(:delete, 'http://localhost/api/files/yolo')
      .to_return(body: "{}\n")

    ::Aptly::Files.delete('yolo')

    assert_requested(:delete, 'http://localhost/api/files/yolo')
  end

  def test_tmp_upload
    file_list = ["yolo/#{__FILE__}"]
    stub_request(:post, %r{http://localhost/api/files/Aptly__Files-(.+)})
      .with(headers: {'Content-Type'=>/multipart\/form-data; boundary=-----------RubyMultipartPost.*/})
      .to_return(body: JSON.generate(file_list))
    stub_request(:delete, %r{http://localhost/api/files/Aptly__Files-(.+)})

    yielded = false
    ::Aptly::Files.tmp_upload([__FILE__]) do |dir|
      assert_includes(dir, 'Aptly__Files-')
      yielded = true
    end
    assert(yielded, 'expected tmp_upload to yield')
  end
end
