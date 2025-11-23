require "test_helper"

module API
  module V1
    class PagesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:default_user)
        @workspace = workspaces(:default_user_workspace)
        # Ensure workspace has some pages
        @workspace.pages.create!(name: "Test Page 1", slug: "test-page-1")
        @workspace.pages.create!(name: "Test Page 2", slug: "test-page-2")

        @token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
      end

      test "should list all pages" do
        get api_v1_pages_url, headers: { "Authorization" => "Bearer #{@token.token}" }
        assert_response :success

        json_response = JSON.parse(response.body)
        assert_kind_of Array, json_response
        assert_equal 2, json_response.length
      end
    end
  end
end
