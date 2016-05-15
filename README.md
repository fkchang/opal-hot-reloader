# OpalHotReloader

opal-hot-reloader is a hot reloader for Opal.  It has built in react.rb support and can be extended to support an arbitrary hook to be run after code is evaluted.  It watches directories specified and when a file is modified it pushes the change via websocket to the client.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'opal_hot_reloader'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install opal_hot_reloader

## Usage

### Server Setup

After adding `gem "opal_hot_loader"` to your gemfile, you must start the server-side part. This will allow websocket connections, and whenever a file is changed it will send it via the socket to listening clients.

To start the server-side of the hotloader:
```
opal-hot-reloader -p 25222 -d dir1,dir2,dir3

Usage: opal-hot-reloader [options]
    -p, --port [INTEGER]             port to run on, defaults to 25222
    -d, --directories x,y,z          comma separated directories to watch
```

For a react.rb Rails you might call it below
```
opal-hot-reloader -d app/assets/javascripts,app/views/components
```

### Client Setup

Require in an opal file (for opal-rails apps application.js.rb is a good place) and start listening for changes:
```ruby
require 'opal_hot_reloader'
OpalHotReloader.listen(25222, true)
```

This will open up a websocket from the client to the server on the given port. The server-side should already be running.

Enjoy!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fkchang/opal_hot_reloader.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

