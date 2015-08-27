require 'rack/ninja_auth/version'
require 'sinatra/base'
require 'omniauth/google_oauth2'

module Rack
  module NinjaAuth
    class Middleware < Sinatra::Base
      use Rack::Session::Pool,
        key: 'rack.ninja_auth',
        expire_after: 2592000

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
        if is_authenticated?
          res = @main_app.call(request.env)
          headers res[1]
          halt res[0], res[2]
        end
      end

      get '/auth/google_oauth2/callback' do
        if (request.env["omniauth.auth"].info.email.match(@email_matcher) rescue false)
          session[:user] = request.env["omniauth.auth"].info.email
          redirect session[:redirect_to]
        else
          redirect '/unauthorized'
        end
      end

      get '/unauthorized' do
        send_file(@not_allowed_file, status: 401)
      end

      after do
        if status == 404
          session[:redirect_to] = env['REQUEST_URI'] == '/auth/google_oauth2' ? '/' : env['REQUEST_URI']
          redirect '/auth/google_oauth2'
        end
      end

      private

      def is_authenticated?
        !!session[:user]
      end
    end
  end
end
