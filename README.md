# Rack::Contrib::Sign

Implement thorough request signing in Rack.

## Installation


    gem 'rack-contrib-sign'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-contrib-sign

## Usage

Install in Rack by adding the following to your config.ru:

```ruby
require 'rack/contrib/sign'
use Rack::Contrib::Sign::Middleware
```

## Specific Authentication Details

This gem works by creating a receipt which gets HMAC hashed with a secret.

