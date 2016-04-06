# Rack::NinjaAuth

Require authentication via google for your application without passing any auth information to your application. This may sound crazy, but it's perfect for securing a test environment.

## Example

Add this as middleware to your rack application so that a rack session is already available, then execute with `NINJA_GOOGLE_CLIENT_ID` AND `NINJA_GOOGLE_CLIENT_SECRET` environment variables set.

```ruby
require 'sinatra'
require 'rack/ninja_auth'

use Rack::NinjaAuth::Middleware, email_matcher: /@gmail.com$/

get '/' do
  "This is secure without authorisation with a google account with an email ending in @gmail.com"
end
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

