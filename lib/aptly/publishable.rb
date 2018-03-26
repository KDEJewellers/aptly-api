module Aptly
  # Abstract "type" of all publishable entities. Publishable entities
  # are everything that can act as Source for a PublishedRepository.
  module Publishable
    # Lists all PublishedRepositories self is published in. Namely self must
    # be a source of the published repository in order for it to appear here.
    # This method always returns an array of affected published repositories.
    # If you use this method with a block it will additionally yield each
    # published repository that would appear in the array, making it a shorthand
    # for Array#each.
    # @yieldparam pub [PublishedRepository]
    # @return [Array<PublishedRepository>]
    def published_in
      Aptly::PublishedRepository.list(connection).select do |pub|
        next false unless pub.Sources.any? do |src|
          src.Name == self.Name
        end
        yield pub if block_given?
        true
      end
    end

    # @return [Boolean]
    def published?
      !published_in.empty?
    end
  end
end
