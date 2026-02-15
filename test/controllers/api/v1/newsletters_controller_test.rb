require "test_helper"

module API
  module V1
    class NewslettersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:default_user)
        @workspace = workspaces(:default_user_workspace)
        @newsletter1 = newsletters(:default_user_newsletter_1)
        @newsletter2 = newsletters(:default_user_newsletter_2)

        @token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
        @headers = { "Authorization" => "Bearer #{@token.token}" }
      end

      # === INDEX (List) ===

      test "index returns paginated envelope" do
        get api_v1_newsletters_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["page"]
        assert_equal 10, json["size"]
        assert_equal 2, json["total"]
        assert_kind_of Array, json["result"]
        assert_equal 2, json["result"].length
      end

      test "index respects size parameter" do
        get api_v1_newsletters_url, params: { size: 1 }, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["size"]
        assert_equal 1, json["result"].length
      end

      test "index returns correct newsletter fields" do
        get api_v1_newsletters_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        newsletter = json["result"].first

        assert newsletter.key?("id")
        assert newsletter.key?("name")
        assert newsletter.key?("name_slug")
        assert newsletter.key?("workspace_id")
        assert newsletter.key?("created_at")
        assert newsletter.key?("updated_at")
      end

      # === SHOW ===

      test "show returns single newsletter" do
        get api_v1_newsletter_url(id: @newsletter1.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @newsletter1.id, json["id"]
        assert_equal @newsletter1.name, json["name"]
        assert_equal @newsletter1.name_slug, json["name_slug"]
      end

      test "show returns 404 for non-existent newsletter" do
        get api_v1_newsletter_url(id: 999999), headers: @headers
        assert_response :not_found
      end

      test "show returns 404 for newsletter from another workspace" do
        other_newsletter = newsletters(:one)
        get api_v1_newsletter_url(id: other_newsletter.id), headers: @headers
        assert_response :not_found
      end

      # === CREATE ===

      test "create creates new newsletter" do
        assert_difference("@workspace.newsletters.count", 1) do
          post api_v1_newsletters_url,
               params: { newsletter: { name: "New Newsletter" } },
               headers: @headers
        end
        assert_response :created

        json = JSON.parse(response.body)
        assert_equal "New Newsletter", json["name"]
        assert json["name_slug"].present?
      end

      test "create returns validation errors" do
        post api_v1_newsletters_url,
             params: { newsletter: { name: "" } },
             headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json.key?("errors")
        assert_kind_of Array, json["errors"]
      end

      # === UPDATE ===

      test "update updates existing newsletter" do
        patch api_v1_newsletter_url(id: @newsletter1.id),
              params: { newsletter: { name: "Updated Name" } },
              headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "Updated Name", json["name"]

        @newsletter1.reload
        assert_equal "Updated Name", @newsletter1.name
      end

      test "update returns validation errors" do
        patch api_v1_newsletter_url(id: @newsletter1.id),
              params: { newsletter: { name: "" } },
              headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json.key?("errors")
      end

      test "update returns 404 for non-existent newsletter" do
        patch api_v1_newsletter_url(id: 999999),
              params: { newsletter: { name: "Test" } },
              headers: @headers
        assert_response :not_found
      end

      # === AUTHENTICATION ===

      test "returns 401 without auth token" do
        get api_v1_newsletters_url
        assert_response :unauthorized
      end

      test "returns 401 with invalid token" do
        get api_v1_newsletters_url, headers: { "Authorization" => "Bearer invalid" }
        assert_response :unauthorized
      end
    end
  end
end
