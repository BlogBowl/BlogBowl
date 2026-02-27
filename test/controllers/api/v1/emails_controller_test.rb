require "test_helper"

module API
  module V1
    class EmailsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:default_user)
        @workspace = workspaces(:default_user_workspace)
        @newsletter = newsletters(:default_user_newsletter_1)
        @email1 = newsletter_emails(:default_user_email_1)
        @email2 = newsletter_emails(:default_user_email_2)

        @token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
        @headers = { "Authorization" => "Bearer #{@token.token}" }
      end

      # === INDEX (List) ===

      test "index returns paginated envelope" do
        get api_v1_newsletter_emails_url(newsletter_id: @newsletter.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["page"]
        assert_equal 10, json["size"]
        assert_equal 2, json["total"]
        assert_kind_of Array, json["result"]
        assert_equal 2, json["result"].length
      end

      test "index filters by status" do
        get api_v1_newsletter_emails_url(newsletter_id: @newsletter.id),
            params: { status: "draft" },
            headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["total"]
        assert_equal "draft", json["result"].first["status"]
      end

      test "index returns correct email fields" do
        get api_v1_newsletter_emails_url(newsletter_id: @newsletter.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        email = json["result"].first

        assert email.key?("id")
        assert email.key?("subject")
        assert email.key?("preview")
        assert email.key?("slug")
        assert email.key?("status")
        assert email.key?("content_html")
        assert email.key?("content_json")
        assert email.key?("author_id")
        assert email.key?("newsletter_id")
        assert email.key?("scheduled_at")
        assert email.key?("sent_at")
        assert email.key?("created_at")
        assert email.key?("updated_at")
      end

      test "index returns 404 for non-existent newsletter" do
        get api_v1_newsletter_emails_url(newsletter_id: 999999), headers: @headers
        assert_response :not_found
      end

      # === SHOW ===

      test "show returns single email" do
        get api_v1_newsletter_email_url(newsletter_id: @newsletter.id, id: @email1.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @email1.id, json["id"]
        assert_equal @email1.subject, json["subject"]
        assert_equal @email1.slug, json["slug"]
      end

      test "show returns 404 for non-existent email" do
        get api_v1_newsletter_email_url(newsletter_id: @newsletter.id, id: 999999), headers: @headers
        assert_response :not_found
      end

      # === CREATE ===

      test "create creates new email" do
        assert_difference("@newsletter.newsletter_emails.count", 1) do
          post api_v1_newsletter_emails_url(newsletter_id: @newsletter.id),
               params: { email: { subject: "New Email", preview: "Preview text" } },
               headers: @headers
        end
        assert_response :created

        json = JSON.parse(response.body)
        assert_equal "New Email", json["subject"]
        assert_equal "Preview text", json["preview"]
        assert_equal "draft", json["status"]
      end

      # === UPDATE ===

      test "update updates draft email" do
        patch api_v1_newsletter_email_url(newsletter_id: @newsletter.id, id: @email1.id),
              params: { email: { subject: "Updated Subject" } },
              headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "Updated Subject", json["subject"]

        @email1.reload
        assert_equal "Updated Subject", @email1.subject
      end

      test "update returns error for sent email" do
        patch api_v1_newsletter_email_url(newsletter_id: @newsletter.id, id: @email2.id),
              params: { email: { subject: "Updated Subject" } },
              headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json.key?("error")
      end

      test "update returns 404 for non-existent email" do
        patch api_v1_newsletter_email_url(newsletter_id: @newsletter.id, id: 999999),
              params: { email: { subject: "Test" } },
              headers: @headers
        assert_response :not_found
      end

      # === DESTROY ===

      test "destroy deletes draft email" do
        assert_difference("@newsletter.newsletter_emails.count", -1) do
          delete api_v1_newsletter_email_url(newsletter_id: @newsletter.id, id: @email1.id),
                 headers: @headers
        end
        assert_response :no_content
      end

      test "destroy returns error for sent email" do
        assert_no_difference("@newsletter.newsletter_emails.count") do
          delete api_v1_newsletter_email_url(newsletter_id: @newsletter.id, id: @email2.id),
                 headers: @headers
        end
        assert_response :unprocessable_entity
      end

      test "destroy returns 404 for non-existent email" do
        delete api_v1_newsletter_email_url(newsletter_id: @newsletter.id, id: 999999),
               headers: @headers
        assert_response :not_found
      end

      # === AUTHENTICATION ===

      test "returns 401 without auth token" do
        get api_v1_newsletter_emails_url(newsletter_id: @newsletter.id)
        assert_response :unauthorized
      end

      test "returns 401 with invalid token" do
        get api_v1_newsletter_emails_url(newsletter_id: @newsletter.id),
            headers: { "Authorization" => "Bearer invalid" }
        assert_response :unauthorized
      end

      # === TIPTAP CONVERSION ===

      test "create with content_html auto-converts to JSON" do
        post api_v1_newsletter_emails_url(newsletter_id: @newsletter.id),
             params: { email: { subject: "HTML Email", content_html: "<p>Email <strong>content</strong></p>" } },
             headers: @headers
        assert_response :created

        json = JSON.parse(response.body)
        assert_equal "<p>Email <strong>content</strong></p>", json["content_html"]
        assert_not_nil json["content_json"]
        assert_kind_of Hash, json["content_json"]
        assert_equal "doc", json["content_json"]["type"]
      end

      test "create with content_md generates HTML and JSON" do
        post api_v1_newsletter_emails_url(newsletter_id: @newsletter.id),
             params: { email: { subject: "MD Email", content_md: "# Newsletter Title\n\nBody text." } },
             headers: @headers
        assert_response :created

        json = JSON.parse(response.body)
        assert_not_nil json["content_html"]
        assert_includes json["content_html"], "Newsletter Title"
        assert_not_nil json["content_json"]
        assert_equal "doc", json["content_json"]["type"]
      end

      test "update with content_html updates JSON" do
        patch api_v1_newsletter_email_url(newsletter_id: @newsletter.id, id: @email1.id),
              params: { email: { content_html: "<p>Updated content</p>" } },
              headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "<p>Updated content</p>", json["content_html"]
        assert_not_nil json["content_json"]
        assert_includes json["content_json"].to_s, "Updated content"
      end

      test "update with content_md updates HTML and JSON" do
        patch api_v1_newsletter_email_url(newsletter_id: @newsletter.id, id: @email1.id),
              params: { email: { content_md: "## Updated via MD\n\nNew content." } },
              headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json["content_html"]
        assert_includes json["content_html"], "Updated via MD"
        assert_not_nil json["content_json"]
        assert_equal "doc", json["content_json"]["type"]
      end

      test "create with HTML strips unsafe tags" do
        dirty_html = '<p>Safe content</p><script>alert("xss")</script>'

        post api_v1_newsletter_emails_url(newsletter_id: @newsletter.id),
             params: { email: { subject: "Sanitize Test", content_html: dirty_html } },
             headers: @headers
        assert_response :created

        json = JSON.parse(response.body)
        assert_not_includes json["content_html"], "<script>"
        assert_includes json["content_html"], "Safe content"
      end
    end
  end
end
