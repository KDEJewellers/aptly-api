# Aptly API

[![Inline docs](http://inch-ci.org/github/KDEJewellers/aptly-api.svg?branch=master)](http://inch-ci.org/github/KDEJewellers/aptly-api)
[![Build Status](https://travis-ci.org/KDEJewellers/aptly-api.svg?branch=master)](https://travis-ci.org/KDEJewellers/aptly-api)
[![Coverage Status](https://coveralls.io/repos/KDEJewellers/aptly-api/badge.svg?branch=master&service=github)](https://coveralls.io/github/KDEJewellers/aptly-api?branch=master)
[![Dependency Status](https://gemnasium.com/KDEJewellers/aptly-api.svg)](https://gemnasium.com/KDEJewellers/aptly-api)
[![Code Climate](https://codeclimate.com/github/KDEJewellers/aptly-api/badges/gpa.svg)](https://codeclimate.com/github/KDEJewellers/aptly-api)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aptly-api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aptly-api

## Usage

```ruby
require 'aptly'

Aptly.configure do |config|
  config.host = 'localhost'
  config.port = 8080
end

repo = Aptly::Repository.create('kewl-new-repo')
repo.upload(['file.deb'])
repo.packages.each do |package|
  puts package
end
repo.publish('public-name', Distribution: 'wily', Architectures: %w(amd64 i386))
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/KDEJewellers/aptly-api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.
