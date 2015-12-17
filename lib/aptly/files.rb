module Aptly
  # Aptly files management.
  # @see http://www.aptly.info/doc/api/files/
  class Files
    class << self
      # Upload files to remote
      # @param files [Array<String>] paths to files to upload
      # @param directory [String] name of the directory to upload to.
      # @param connection [Connection] connection to use
      # @return [Array<String>] list of files now on the remote
      def upload(files, directory, connection = Connection.new, **kwords)
        i = 0
        files.each do |f|
          kwords["file_#{i += 1}".to_sym] = f
        end
        response = connection.send(:post, "/files/#{directory}",
                                   kwords)
        JSON.parse(response.body)
      end
    end
  end
end
