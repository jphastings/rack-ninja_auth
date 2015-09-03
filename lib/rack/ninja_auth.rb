require 'rack/ninja_auth/version'
require 'sinatra/base'
require 'omniauth/google_oauth2'
require 'rack/session/redis'
require 'rack/accept'

module Rack
  module NinjaAuth
    class Middleware < Sinatra::Base
      use Rack::Accept
      use Rack::Session::Redis,
        key: 'rack.ninja_auth',
        expire_after: 2592000,
        redis_server: ENV['NINJA_REDIS_URL'] || 'redis://127.0.0.1:6379/0/rack:ninja_auth'

      raise "Please set NINJA_GOOGLE_CLIENT_ID and NINJA_GOOGLE_CLIENT_SECRET to use NinjaAuth" unless ENV["NINJA_GOOGLE_CLIENT_ID"] && ENV["NINJA_GOOGLE_CLIENT_SECRET"]
      use OmniAuth::Builder do
        provider :google_oauth2, ENV["NINJA_GOOGLE_CLIENT_ID"], ENV["NINJA_GOOGLE_CLIENT_SECRET"]
      end

      def initialize(app, email_matcher = //, not_allowed_file = nil)
        @main_app = app
        @email_matcher = email_matcher
        @not_allowed_file = not_allowed_file || ::File.expand_path('../../../views/401.html', __FILE__)
        super()
      end

      before do
        @hit_real_app = false
        if is_authenticated?
          res = @main_app.call(request.env)
          @hit_real_app = true
          headers res[1]
          halt res[0], res[2]
        end
      end

      get '/auth/google_oauth2/callback' do
        if (request.env["omniauth.auth"].info.email.match(@email_matcher) rescue false)
          session[:user] = request.env["omniauth.auth"].info.email
          redirect session[:redirect_to]
        else
          redirect '/auth/failure'
        end
      end

      get '/auth/failure' do
        send_file(@not_allowed_file, status: 401)
      end

      after do
        if !@hit_real_app && status == 404
          halt(403) unless env['rack-accept.request'].media_type?('text/html')
          session[:redirect_to] = env['REQUEST_URI'] =~ %r{^/auth/google_oauth2} ? '/' : env['REQUEST_URI']
          redirect '/auth/google_oauth2'
        end
      end

      private

      def is_authenticated?
        !session[:user].nil?
      end
    end
  end
end
