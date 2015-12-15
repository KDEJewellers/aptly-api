require 'socket'
require 'tmpdir'

require_relative 'representation'

module Aptly
  # Aptly repository representation.
  class Repository < Representation
    # Delete this repository.
    def delete(**kwords)
      connection.send(:delete, "/repos/#{self.Name}", query: kwords)
    end

    # Add a previously uploaded file to the Repository.
    # @return [Hash] report data as specified in the API.
    def add_file(path, **kwords)
      kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
      response = connection.send(:post, "/repos/#{self.Name}/file/#{path}",
                                 query: kwords)
      JSON.parse(response.body)
    end

    # FIXME: needs to support single files
    # Convenience wrapper around {Files.upload} and {#add_file}
    def upload(files)
      prefix = "#{self.class.to_s.tr(':', '_')}-#{Socket.gethostname}-"
      directory = Dir::Tmpname.make_tmpname(prefix, nil)
      files = Files.upload(files, directory, connection)
      files.each { |f| add_file(f) }
    ensure
      # FIXME: delete dir?
    end

    def packages(**kwords)
      response = connection.send(:get, "/repos/#{self.Name}/packages",
                                 query: kwords)
      JSON.parse(response.body)
    end

    # Convenience wrapper around {Aptly.publish}
    # @return [PublishedRepository]
    def publish(prefix, **kwords)
      Aptly.publish([{ Name: self.Name }], prefix, 'local', kwords)
    end

    # @return [Boolean]
    def published?
      !published_in.empty?
    end

    # @yieldparam pub [PublishedRepository]
    # @return [Array<PublishedRepository>]
    def published_in
      Aptly::PublishedRepository.list(connection).select do |pub|
        pub.Sources.each do |src|
          next false unless src.Name == self.Name
          yield repo if block_given?
          true
        end
      end
    end

    class << self
      # FIXME: This mixes representation with client, is that good?
      def get(name, connection = Connection.new, **kwords)
        kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
        response = connection.send(:get, "/repos/#{name}",
                                   query: kwords)
        new(connection, JSON.parse(response.body))
      end

      def create(name, connection = Connection.new, **kwords)
        options = kwords.merge(name: name)
        options = options.map { |k, v| [k.to_s.capitalize, v] }.to_h
        response = connection.send(:post, '/repos',
                                   body: JSON.generate(options))
        new(connection, JSON.parse(response.body))
      end
    end
  end
end
