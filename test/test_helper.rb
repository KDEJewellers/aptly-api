require 'codeclimate-test-reporter'
require 'coveralls'
require 'simplecov'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    CodeClimate::TestReporter::Formatter,
    Coveralls::SimpleCov::Formatter,
    SimpleCov::Formatter::HTMLFormatter
  ]
)
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'aptly'

require 'webmock/minitest'

require 'minitest/autorun'
