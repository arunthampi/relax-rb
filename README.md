# Relax

Relax is a Ruby client/consumer library for [relax](https://github.com/zerobotlabs/relax) &ndash; which is a multitenant message broker for Slack.

![Travis Badge for relax-rb](https://api.travis-ci.org/zerobotlabs/relax-rb.svg?branch=master)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'relax'
```

And then execute:

    $ bundle

## Usage (with Rails)

[Relax](https://github.com/zerobotlabs/relax) is meant to be used in
conjunction with a web app such as Rails. There are two primary
functions that this library lets you perform:

* Start Slack bots on Relax

* Listen for events generated by Relax.

### Setup (Environment Variables)

The Relax Ruby client requires a few environment variables to be set up
(these same environment variables are also used to set up the relax
message broker).

`RELAX_BOTS_KEY`: This can be any string value and is used to store state
about all Slack clients currently controlled by Relax in Redis. (Used by
`Relax::Bot`)

`RELAX_BOTS_PUBSUB`: This can be any string value and is used to notify
Relax brokers that a new Slack bot has been started. (Used by
`Relax::Bot`)

`RELAX_EVENTS_QUEUE`: This can be any string value and is used by Relax
brokers to send events to the client. (Used by `Relax::EventListener`)

For a full list of events that are sent from Relax brokers, visit the
[Relax Github page](https://github.com/zerobotlabs/relax).

### Starting Bots

To start a bot, or update a bot with a new token, call
`Relax::Bot.start!(team_uid, token)` where `team_uid` is the UID of the
team (generated by the Slack API) and `token` is the API token for the
bot (again generated by the Slack API).

If a token is invalid or a bot connection is unsuccesful, you will
receive a `disable_bot` event.

### Listening for Events

Events are queued in Redis by Relax brokers in the `REDIS_EVENTS_QUEUE`
key and `Relax::EventListener.listen!` listens for events and invokes
the callback that is set by `Relax::EventListener.callback=`.

#### Setting the callback

The recommended way to set the callback method for events in Rails is an
initializer, for e.g. in a file `config/initializers/relax.rb`:

```ruby
callback = Proc.new do |event|
  Rails.logger.info "received event: #{event}"
  # handle event
end

Relax::EventListener.callback = callback
```

The callback can also be a class (or instance) method, in which case you should do
something like this:

```ruby
class RelaxEventHandler
  def self.handle_event(event)
    Rails.logger.info "received event: #{event}"
    # handle event
  end
end

Relax::EventListener.callback = RelaxEventHandler.method(:handle_event)
```

#### Starting the Listener

The recommended way to start the listener in a Rails app is to use
[Foreman](https://github.com/ddollar/foreman). In your Procfile, create
an entry like this:

`relax: bundle exec rake relax:listen_for_events`

And this will invoke `Relax::EventListener.listen!` as part your of your
Rails application.

This process can be scaled indepedently from the rest of your web
application, and so the more events you get, the more "relax" listener
processes you can have.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zerobotlabs/relax-rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

