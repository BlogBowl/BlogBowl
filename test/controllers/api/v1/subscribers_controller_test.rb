require "test_helper"

module API
  module V1
    class SubscribersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:default_user)
        @workspace = workspaces(:default_user_workspace)
        @newsletter = newsletters(:default_user_newsletter_1)
        @subscriber1 = subscribers(:default_user_subscriber_1)
        @subscriber2 = subscribers(:default_user_subscriber_2)

        @token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
        @headers = { "Authorization" => "Bearer #{@token.token}" }
      end

      # === INDEX (List) ===

      test "index returns paginated envelope" do
        get api_v1_newsletter_subscribers_url(newsletter_id: @newsletter.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["page"]
        assert_equal 10, json["size"]
        assert_equal 2, json["total"]
        assert_kind_of Array, json["result"]
        assert_equal 2, json["result"].length
      end

      test "index filters by status" do
        get api_v1_newsletter_subscribers_url(newsletter_id: @newsletter.id),
            params: { status: "active" },
            headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["total"]
        assert_equal "active", json["result"].first["status"]
      end

      test "index filters by verified" do
        get api_v1_newsletter_subscribers_url(newsletter_id: @newsletter.id),
            params: { verified: true },
            headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["total"]
        assert_equal true, json["result"].first["verified"]
      end

      test "index returns correct subscriber fields" do
        get api_v1_newsletter_subscribers_url(newsletter_id: @newsletter.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        subscriber = json["result"].first

        assert subscriber.key?("id")
        assert subscriber.key?("email")
        assert subscriber.key?("verified")
        assert subscriber.key?("active")
        assert subscriber.key?("status")
        assert subscriber.key?("newsletter_id")
        assert subscriber.key?("verified_at")
        assert subscriber.key?("created_at")
        assert subscriber.key?("updated_at")
      end

      test "index returns 404 for non-existent newsletter" do
        get api_v1_newsletter_subscribers_url(newsletter_id: 999999), headers: @headers
        assert_response :not_found
      end

      # === CREATE (Upsert) ===

      test "create creates new subscriber as active and verified" do
        assert_difference("@newsletter.subscribers.count", 1) do
          post api_v1_newsletter_subscribers_url(newsletter_id: @newsletter.id),
               params: { subscriber: { email: "new@example.com" } },
               headers: @headers
        end
        assert_response :created

        json = JSON.parse(response.body)
        assert_equal "new@example.com", json["email"]
        assert_equal "active", json["status"]
        assert_equal true, json["verified"]
        assert_not_nil json["verified_at"]
      end

      test "create returns existing subscriber (upsert)" do
        assert_no_difference("@newsletter.subscribers.count") do
          post api_v1_newsletter_subscribers_url(newsletter_id: @newsletter.id),
               params: { subscriber: { email: @subscriber1.email } },
               headers: @headers
        end
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @subscriber1.id, json["id"]
        assert_equal @subscriber1.email, json["email"]
      end

      test "create returns validation errors for invalid email" do
        post api_v1_newsletter_subscribers_url(newsletter_id: @newsletter.id),
             params: { subscriber: { email: "" } },
             headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json.key?("errors")
      end

      # === DESTROY ===

      test "destroy deletes subscriber" do
        assert_difference("@newsletter.subscribers.count", -1) do
          delete api_v1_newsletter_subscriber_url(newsletter_id: @newsletter.id, id: @subscriber1.id),
                 headers: @headers
        end
        assert_response :no_content
      end

      test "destroy returns 404 for non-existent subscriber" do
        delete api_v1_newsletter_subscriber_url(newsletter_id: @newsletter.id, id: 999999),
               headers: @headers
        assert_response :not_found
      end

      # === AUTHENTICATION ===

      test "returns 401 without auth token" do
        get api_v1_newsletter_subscribers_url(newsletter_id: @newsletter.id)
        assert_response :unauthorized
      end

      test "returns 401 with invalid token" do
        get api_v1_newsletter_subscribers_url(newsletter_id: @newsletter.id),
            headers: { "Authorization" => "Bearer invalid" }
        assert_response :unauthorized
      end
    end
  end
end
