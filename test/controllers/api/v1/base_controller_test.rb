require "test_helper"

module API
  module V1
    class BaseControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:default_user)
        @workspace = workspaces(:default_user_workspace)

        @token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
      end

      test "should get index with valid token" do
        get api_v1_pages_url, headers: { "Authorization" => "Bearer #{@token.token}" }
        assert_response :success

        json_response = JSON.parse(response.body)
        assert_kind_of Array, json_response
        assert_equal 0, json_response.length
      end

      test "should return unauthorized without token" do
        get api_v1_pages_url
        assert_response :unauthorized
      end

      test "should return unauthorized with invalid token" do
        get api_v1_pages_url, headers: { "Authorization" => "Bearer invalid_token" }
        assert_response :unauthorized
      end

      test "should return rate limit error after 1000 requests" do
        limit = 1000
        test_ip = "1.2.3.4"

        request_headers = {
          "Authorization" => "Bearer #{@token.token}",
          "REMOTE_ADDR" => test_ip
        }

        # Send 'limit' number of successful requests (1 to 1000)
        limit.times do |i|
          # Use `get` and ensure each request is successful (200 OK)
          get api_v1_pages_url, headers: request_headers
          assert_response :success, "Request #{i + 1} failed unexpectedly."
        end

        # The 1001st request should be rate-limited (HTTP 429 Too Many Requests)
        get api_v1_pages_url, headers: request_headers
        assert_response :too_many_requests, "The 1001st request was not rate-limited (expected 429)."
      end
    end
  end
end
