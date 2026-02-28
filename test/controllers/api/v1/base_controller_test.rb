require "test_helper"

module API
  module V1
    class BaseControllerTest < ActionDispatch::IntegrationTest
      setup do
        Rack::Attack.reset!
        @user = users(:default_user)
        @workspace = workspaces(:default_user_workspace)

        @token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
      end

      test "should get index with valid token" do
        get api_v1_pages_url, headers: { "Authorization" => "Bearer #{@token.token}" }
        assert_response :success

        # Collections should return pagination envelope (Hash)
        json_response = JSON.parse(response.body)
        assert_kind_of Hash, json_response
        assert_equal 1, json_response['page']
        assert_equal 10, json_response['size']
        assert_equal 2, json_response['total']

        # Envelope should contain array of resources in 'result'
        assert_kind_of Array, json_response['result']
        assert_equal 2, json_response['result'].length

        # Each resource in the array should be a Hash
        json_response['result'].each do |resource|
          assert_kind_of Hash, resource
          assert resource.key?('id')
        end
      end

      test "should get single resource as unwrapped hash" do
        page = @workspace.pages.first
        get api_v1_page_url(id: page.id), headers: { "Authorization" => "Bearer #{@token.token}" }
        assert_response :success

        # Single resources should return unwrapped Hash (not pagination envelope)
        json_response = JSON.parse(response.body)
        assert_kind_of Hash, json_response

        # Should have resource fields directly (not wrapped in 'result')
        assert_equal page.id, json_response['id']
        assert_equal page.name, json_response['name']

        # Should NOT have pagination envelope keys
        assert_nil json_response['page']
        assert_nil json_response['size']
        assert_nil json_response['total']
        assert_nil json_response['result']
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
        period = 1.minute.to_i

        request_headers = {
          "Authorization" => "Bearer #{@token.token}",
          "REMOTE_ADDR" => test_ip
        }

        # Pre-fill the Rack::Attack counter to one below the limit.
        # Making 999 real HTTP requests would be too slow in CI and risks
        # spanning the 1-minute throttle window, causing flaky failures.
        (limit - 1).times { Rack::Attack.cache.count("api/v1/ip:#{test_ip}", period) }

        # The 1000th request should still succeed (counter reaches limit, not exceeded)
        get api_v1_pages_url, headers: request_headers
        assert_response :success, "The 1000th request was unexpectedly rate-limited."

        # The 1001st request should be rate-limited (HTTP 429 Too Many Requests)
        get api_v1_pages_url, headers: request_headers
        assert_response :too_many_requests, "The 1001st request was not rate-limited (expected 429)."
      end
    end
  end
end
