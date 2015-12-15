module Aptly
  # Aptly files management.
  # http://www.aptly.info/doc/api/files/
  class Files
    class << self
      # 404	directory doesn’t exist
      def upload(files, directory, connection = Connection.new, **kwords)
        kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
        i = 0
        files.each do |f|
          kwords["file#{i += 1}".to_sym] = File.new(f)
        end
        response = connection.send(:post, "/files/#{directory}",
                                   body: kwords)
        JSON.parse(response.body)
      end
    end
  end
end
