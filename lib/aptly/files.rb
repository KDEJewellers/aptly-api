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
        files.each_with_index { |f, i| kwords["file_#{i}".to_sym] = f }
        response = connection.send(:post, "/files/#{directory}", kwords)
        JSON.parse(response.body)
      end

      # Delete files from remote's upload directory.
      # @param path [String] path to delete (this may be a directory or a file)
      # @return [nil]
      def delete(path, connection = Connection.new, **kwords)
        connection.send(:delete, "/files/#{path}", kwords)
        nil
      end
    end
  end
end
