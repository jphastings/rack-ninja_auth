require 'spec_helper'
require 'rack/test'

OmniAuth.config.test_mode = true

describe Rack::NinjaAuth::Middleware do
  include Rack::Test::Methods

  let(:content) { 'Exciting content!' }
  let(:session) { {} }
  let(:email) { nil }
  let(:rack_vars) { { :'omniauth.auth' => OmniAuth.config.mock_auth[:google], 'rack.session' => { 'rack-ninja_auth' => session } } }
  let(:base_app) { proc { [200, {}, [content]] } }
  let(:app) { described_class.new(base_app, email_matcher: email_matcher, secured_routes: secured_routes) }
  let(:email_matcher) { %r{@acceptable.com$} }

  subject { last_response }

  before do
    auth_as(email: email) if email
    get(path, {}, rack_vars)
  end

  context 'when all paths are secured' do
    let(:secured_routes) { %r{} }

    context 'when unauthenticated' do

      context 'visiting a path that exists in the app' do
        let(:path) { '/path' }

        its(:status) { should eq 302 }
        it('should redirect to Google Auth') { expect(subject.headers['Location']).to eq "http://example.org/auth/google_oauth2" }
      end
    end

    context 'when authenticated as an acceptable user' do
      let(:email) { 'person@acceptable.com' }

      context 'visiting the auth callback' do
        let(:path) { '/auth/google_oauth2/callback' }
        let(:session) { {} }

        its(:status) { should eq 302 }
        it('should redirect to the root') { expect(subject.headers['Location']).to eq "http://example.org/" }
      end

      context 'with a validated session' do
        let(:session) { { email: email } }

        context 'visiting a path that exists in the app' do
          let(:path) { '/path' }

          its(:status) { should eq 200 }
          its(:body) { should include content }
        end
      end
    end

    context 'when authenticated as an unacceptable user' do
      let(:email) { 'person@unacceptable.no' }

      context 'visiting the auth callback' do
        let(:path) { '/auth/google_oauth2/callback' }

        its(:status) { should eq 302 }
        it('should redirect to the auth failure page') { expect(subject.headers['Location']).to eq "http://example.org/auth/failure" }
      end
    end
  end

  context 'when some paths are secured' do
    let(:secured_routes) { %r{^/secured} }

    context 'when unauthenticated' do

      context 'visiting a secured path' do
        let(:path) { '/secured/path' }

        its(:status) { should eq 302 }
        it('should redirect to Google Auth') { expect(subject.headers['Location']).to eq "http://example.org/auth/google_oauth2" }
      end

      context 'visiting an unsecured path' do
        let(:path) { '/public' }

        its(:status) { should eq 200 }
        its(:body) { should include content }
      end
    end

    context 'when authenticated as an unacceptable user' do
      let(:email) { 'person@unacceptable.no' }

      context 'visiting a secured path' do
        let(:path) { '/secured/path' }

        its(:status) { should eq 302 }
        it('should redirect to Google Auth') { expect(subject.headers['Location']).to eq "http://example.org/auth/google_oauth2" }
      end

      context 'visiting an unsecured path' do
        let(:path) { '/public' }

        its(:status) { should eq 200 }
        its(:body) { should include content }
      end
    end

    context 'when authenticated as an acceptable user' do
      let(:email) { 'person@acceptable.com' }

      context 'with a validated session' do
        let(:session) { { email: email } }

        context 'visiting a secured path' do
          let(:path) { '/secured/path' }

          its(:status) { should eq 200 }
          its(:body) { should include content }
        end

        context 'visiting an unsecured path' do
          let(:path) { '/public' }

          its(:status) { should eq 200 }
          its(:body) { should include content }
        end
      end
    end
  end

  def auth_as(info = {})
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: 'google',
      uid: '42',
      info: info
    })
  end
end
