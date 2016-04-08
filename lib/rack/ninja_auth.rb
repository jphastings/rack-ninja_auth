require 'rack/ninja_auth/version'
require 'sinatra/base'
require 'omniauth/google_oauth2'
require 'rack/accept'

module Rack
  module NinjaAuth
    class Middleware < Sinatra::Base
      use Rack::Accept

      SESSION_KEY = 'rack-ninja_auth'
      SALT_BYTES = 16

      use OmniAuth::Builder do
        provider :google_oauth2, ENV["NINJA_GOOGLE_CLIENT_ID"], ENV["NINJA_GOOGLE_CLIENT_SECRET"]
      end

      def initialize(app, email_matcher: //, secured_routes: //, not_allowed_file: nil, authorized_file: nil)
        $stderr.puts "Please set NINJA_GOOGLE_CLIENT_ID and NINJA_GOOGLE_CLIENT_SECRET to use NinjaAuth" unless ENV["NINJA_GOOGLE_CLIENT_ID"] && ENV["NINJA_GOOGLE_CLIENT_SECRET"]
        @main_app = app
        @email_matcher = email_matcher
        @secured_route_matcher = secured_routes
        @not_allowed_file = ::File.join(__dir__, '../../views/401.html')
        @not_allowed_file = not_allowed_file if not_allowed_file && ::File.exists?(not_allowed_file)
        @authorized_file = ::File.join(__dir__, '../../views/200.html')
        @authorized_file = authorized_file if authorized_file && ::File.exists?(authorized_file)
        super()
      end

      before do
        @hit_real_app = false
        if !is_internal_request? && (is_authenticated? || is_unprotected_request?)
          res = @main_app.call(request.env)
          @hit_real_app = true
          headers res[1]
          halt res[0], res[2]
        end
      end

      get '/auth/google_oauth2/callback' do
        email = request.env["omniauth.auth"].info.email rescue nil
        if allowable_email?(email)
          authenticate!(email: email)
          send_file(@authorized_file, status: 200)
        else
          send_file(@not_allowed_file, status: 403)
        end
      end

      after do
        if !@hit_real_app && !is_internal_request?
          halt(403) unless env['rack-accept.request'].media_type?('text/html')
          headers['X-Cascade'] = 'stop'
          redirect '/auth/google_oauth2'
        end
      end

      private

      def authenticate!(email:)
        session[SESSION_KEY] = { email: email }
      end

      def allowable_email?(email)
        email.respond_to?(:match) && email.match(@email_matcher)
      end

      def is_authenticated?
        fields = session[SESSION_KEY] || {}
        allowable_email?(fields[:email])
      end

      def is_unprotected_request?
        !env['PATH_INFO'].match(@secured_route_matcher)
      end

      def is_internal_request?
        !!env['REQUEST_URI'].match(%r{^/auth/google_oauth2})
      end
    end
  end
end
