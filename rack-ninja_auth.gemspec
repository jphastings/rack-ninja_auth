# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/ninja_auth/version'

Gem::Specification.new do |spec|
  spec.name          = "rack-ninja_auth"
  spec.version       = Rack::NinjaAuth::VERSION
  spec.authors       = ["JP Hastings-Spital"]
  spec.email         = ["jp@deliveroo.co.uk"]

  spec.summary       = %q{Secure your test rigs with google.}
  spec.description   = %q{Transparently secure your rack application with google. For test rigs etc.}
  spec.homepage      = "https://github.com/jphastings/rack-ninja_auth"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra", "~> 1.4"
  spec.add_dependency "omniauth-google-oauth2", "~> 0.2"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
