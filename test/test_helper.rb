require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'aptly'

require 'minitest/autorun'

require 'webmock/minitest'
