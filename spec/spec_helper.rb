$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rack/ninja_auth'
require 'rspec/its'

ENV['NINJA_GOOGLE_CLIENT_ID'] = "test-client-id"
ENV['NINJA_GOOGLE_CLIENT_SECRET'] = "test-client-secret"