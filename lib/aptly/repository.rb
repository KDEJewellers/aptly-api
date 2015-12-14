require 'ostruct'
require 'socket'
require 'tmpdir'

require_relative 'representation'

module Aptly
  class Repository < Representation
    # 404	repository with such name doesn’t exist
    # 409	repository can’t be dropped (reason in the message)
    def delete(**kwords)
      connection.send(:delete, "/repos/#{self.Name}",
                      query: kwords)
      # 409 #<HTTParty::Response:0x25381d8 parsed_response=[{"error"=>"unable to drop, local repo is published", "meta"=>"Operation aborted"}], @response=#<Net::HTTPConflict 409 Conflict readbody=true>, @headers={"content-type"=>["application/json; charset=utf-8"], "date"=>["Fri, 11 Dec 2015 11:28:39 GMT"], "content-length"=>["81"]}>
    end

    # 404	repository with such name doesn’t exist
    # @return [Hash] report data as specified in the API.
    def add_file(path, **kwords)
      kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
      response = connection.send(:post, "/repos/#{self.Name}/file/#{path}",
                                 query: kwords)
      JSON.parse(response.body)
    end

    # Convenience wrapper around {Files.upload} and {#add_file}
    def upload(files)
      prefix = "#{self.class.to_s.tr(':', '_')}-#{Socket.gethostname}-"
      directory = Dir::Tmpname.make_tmpname(prefix, nil)
      files = Files.upload(files, directory, connection)
      files.each { |f| add_file(f) }
    ensure
      # FIXME: delete dir?
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
      # 404	repository with such name doesn’t exist
      def get(name, connection = Connection.new, **kwords)
        kwords = kwords.map { |k, v| [k.to_s.capitalize, v] }.to_h
        response = connection.send(:get, "/repos/#{name}",
                                   query: kwords)
        new(connection, JSON.parse(response.body))
      end

      # 400	repository with such name already exists
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
