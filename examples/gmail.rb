$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
# Make sure you run this with the appropriate environment variables set:
#
# ```
# NINJA_GOOGLE_CLIENT_ID=<Your google client id>
# NINJA_GOOGLE_CLIENT_SECRET=<Your google client secret>
# ruby gmail.rb
# ```
#
# Now you can visit `http://127.0.0.1:4567/secured` and will only access it if you validate with a google
# account that has an `@gmail.com` email address.

require 'sinatra'
require 'rack/ninja_auth'

use Rack::Session::Cookie, secret: 'change_me'
use Rack::NinjaAuth::Middleware, email_matcher: /@gmail.com$/
# use Rack::NinjaAuth::Middleware, email_matcher: /@gmail\./, not_allowed_file: './file/to/deliver/if/email/does/not/match.html'

get '/secured' do
  "You hit the secured app"
end