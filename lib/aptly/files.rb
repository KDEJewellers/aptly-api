# Copyright (C) 2015-2018 Harald Sitter <sitter@kde.org>
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

      # Upload files into a temporary directory on remote.
      # This method expects a block which will be yielded to with the directory
      # name on the remote. The directory will be deleted when this method
      # returns.
      # You'll generally want to use this instead of #upload so you don't have
      # to worry about name collission and clean up.
      #
      # @param files [Array<String>] paths to files to upload
      # @param connection [Connection] connection to use
      # @yield [String] the remote directory name the files were uploaded to
      # @return return value of block
      #
      # @example Can be used to push into multiple repositories with one upload
      #   Files.tmp_upload(files) do |d|
      #     repos.each { |r| r.add_files(d, noRemove: 1) }
      #   end
      #
      # @since 0.9.0
      def tmp_upload(files, connection = Connection.new, **kwords)
        # TODO: 1.0 find out if #upload even has a use case and maybe replace it
        dir = tmp_dir_name
        upload(files, dir, connection, **kwords)
        uploaded = true
        yield dir
      ensure
        # We have an uploaded var here as exceptions raised by upload would
        # still run this, but they may not have the remote file, so our
        # delete request would again cause an error making it harder to spot
        # the orignal problem.
        delete(dir) if uploaded
      end

      # Delete files from remote's upload directory.
      # @param path [String] path to delete (this may be a directory or a file)
      # @return [nil]
      def delete(path, connection = Connection.new, **kwords)
        connection.send(:delete, "/files/#{path}", kwords)
        nil
      end

      private

      def tmp_dir_name
        prefix = "#{to_s.tr(':', '_')}-#{Socket.gethostname}"
        TmpName.dir(prefix)
      end
    end
  end
end
