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
        path: '/',
        key: 'rack.ninja_auth',
        expire_after: 2592000,
        redis_server: ENV['NINJA_REDIS_URL'] || 'redis://127.0.0.1:6379/0/rack:ninja_auth'

      use OmniAuth::Builder do
        provider :google_oauth2, ENV["NINJA_GOOGLE_CLIENT_ID"], ENV["NINJA_GOOGLE_CLIENT_SECRET"]
      end

      def initialize(app, email_matcher: //, secured_routes: //, not_allowed_file: nil, remember_original_path: true)
        $stderr.puts "Please set NINJA_GOOGLE_CLIENT_ID and NINJA_GOOGLE_CLIENT_SECRET to use NinjaAuth" unless ENV["NINJA_GOOGLE_CLIENT_ID"] && ENV["NINJA_GOOGLE_CLIENT_SECRET"]
        @main_app = app
        @email_matcher = email_matcher
        @remember_original_path = remember_original_path
        @secured_route_matcher = secured_routes
        @not_allowed_file = not_allowed_file || ::File.expand_path('../../../views/401.html', __FILE__)
        super()
      end

      before do
        @hit_real_app = false
        if is_authenticated? || !is_protected_request?
          res = @main_app.call(request.env)
          @hit_real_app = true
          headers res[1]
          halt res[0], res[2]
        end
      end

      get '/auth/google_oauth2/callback' do
        if (request.env["omniauth.auth"].info.email.match(@email_matcher) rescue false)
          session[:user] = request.env["omniauth.auth"].info.email
          redirect_url = session[:redirect_to] if @remember_original_path
          redirect redirect_url || '/'
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
          session[:redirect_to] = env['REQUEST_URI'] if @remember_original_path && is_internal_request?
          redirect '/auth/google_oauth2'
        end
      end

      private

      def is_authenticated?
        !session[:user].nil?
      end

      def is_protected_request?
        is_internal_request? || env['PATH_INFO'].match(@secured_route_matcher)
      end

      def is_internal_request?
        env['REQUEST_URI'] =~ %r{^/auth/}
      end
    end
  end
end
