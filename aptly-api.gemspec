# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aptly/version'

Gem::Specification.new do |spec|
  spec.name          = 'aptly-api'
  spec.version       = Aptly::VERSION
  spec.authors       = ['Harald Sitter', 'Rohan Garg']
  spec.email         = ['sitter@kde.org']

  spec.summary       = 'REST client for the Aptly API'
  spec.description   = 'REST client for the Aptly API'
  spec.homepage      = 'https://github.com/KDEJewellers/aptly-api/'
  spec.license       = 'LGPL-3.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.8'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rake-notes', '~> 0.2'
  spec.add_development_dependency 'simplecov', '~> 0.11'
  spec.add_development_dependency 'webmock', '~> 3.1'
  spec.add_development_dependency 'yard', '~> 0.8'

  spec.add_dependency 'faraday', '~> 0.9'
  spec.add_dependency 'excon', '~> 0.71'
end
