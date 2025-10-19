ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "bcrypt"
require 'webmock/minitest'

require 'app_logger'

WebMock.disable_net_connect!(allow_localhost: true, allow: /digitaloceanspaces\.com/)


class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def sign_in_as(user)
    post(sign_in_url, params: { email: user.email, password: "Secret1*3*5*" }); user
  end

  def sign_in_as_pas(user, password)
    post(sign_in_url, params: { email: user.email, password: password }); user
  end
end
