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
      .with(headers: {'Content-Type'=>'multipart/form-data; boundary=-----------RubyMultipartPost'})
      .to_return(body: JSON.generate(file_list))

    files = ::Aptly::Files.upload([__FILE__], 'yolo')

    assert_equal file_list, files
    assert_requested(:post, 'http://localhost/api/files/yolo')
  end
end
