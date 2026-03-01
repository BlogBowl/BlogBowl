ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "bcrypt"
require 'webmock/minitest'

WebMock.disable_net_connect!(allow_localhost: true, allow: /digitaloceanspaces\.com/)


class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: 1)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def sign_in_as(user)
    post(sign_in_url, params: { email: user.email, password: "Secret1*3*5*" }); user
  end

  def sign_in_as_pas(user, password)
    post(sign_in_url, params: { email: user.email, password: password }); user
  end

  setup do
    stub_request(:post, "https://api.postmarkapp.com/servers").
      to_return(
        status: 200,
        body: { id: 'mocked_postmark_server_id', api_tokens: ['first_api_token'] }.to_json,
      )
    stub_request(:post, "https://api.postmarkapp.com/webhooks").
      to_return(
        status: 200,
        body: { id: 'mocked_postmark_server_id', api_tokens: ['first_api_token'] }.to_json,
      )
  end
end
