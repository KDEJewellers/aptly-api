# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aptly/version'

Gem::Specification.new do |spec|
  spec.name          = 'aptly-api'
  spec.version       = Aptly::VERSION
  spec.authors       = ['Harald Sitter']
  spec.email         = ['sitter@kde.org']

  spec.summary       = 'REST client for the Aptly API'
  spec.description   = 'REST client for the Aptly API'
  spec.homepage      = 'https://github.com/KDEJewellers/aptly-api/'
  spec.license       = 'LGPL-3.0'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    fail 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 0.4'
  spec.add_development_dependency 'coveralls', '~> 0.8'
  spec.add_development_dependency 'minitest', '~> 5.8'
  spec.add_development_dependency 'rake', '~> 10.4'
  spec.add_development_dependency 'rake-notes', '~> 0.2'
  spec.add_development_dependency 'simplecov', '~> 0.11'
  spec.add_development_dependency 'webmock', '~> 1.22'
  spec.add_development_dependency 'yard', '~> 0.8'

  spec.add_dependency 'faraday', '~> 0.9'
end
