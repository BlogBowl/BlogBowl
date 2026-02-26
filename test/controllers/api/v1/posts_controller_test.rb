require "test_helper"

module API
  module V1
    class PostsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:default_user)
        @workspace = workspaces(:default_user_workspace)
        @page = pages(:default_user_page_1)
        @post1 = posts(:default_user_post_1)
        @post2 = posts(:default_user_post_2)
        @category = categories(:default_user_category_1)

        @token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
        @headers = { "Authorization" => "Bearer #{@token.token}" }
      end

      # === INDEX (List) ===

      test "index returns paginated envelope" do
        get api_v1_page_posts_url(page_id: @page.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["page"]
        assert_equal 10, json["size"]
        assert_equal 2, json["total"]
        assert_kind_of Array, json["result"]
        assert_equal 2, json["result"].length
      end

      test "index filters by status" do
        get api_v1_page_posts_url(page_id: @page.id), params: { status: "draft" }, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["total"]
        assert_equal "draft", json["result"].first["status"]
      end

      test "index filters by category_id" do
        @post1.update!(category: @category)

        get api_v1_page_posts_url(page_id: @page.id), params: { category_id: @category.id }, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["total"]
        assert_equal @post1.id, json["result"].first["id"]
      end

      test "index returns correct post fields" do
        get api_v1_page_posts_url(page_id: @page.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        post = json["result"].first

        assert post.key?("id")
        assert post.key?("title")
        assert post.key?("slug")
        assert post.key?("status")
        assert post.key?("description")
        assert post.key?("content_html")
        assert post.key?("content_json")
        assert post.key?("seo_title")
        assert post.key?("seo_description")
        assert post.key?("og_title")
        assert post.key?("og_description")
        assert post.key?("category_id")
        assert post.key?("page_id")
        assert post.key?("scheduled_at")
        assert post.key?("first_published_at")
        assert post.key?("created_at")
        assert post.key?("updated_at")
      end

      test "index returns 404 for non-existent page" do
        get api_v1_page_posts_url(page_id: 999999), headers: @headers
        assert_response :not_found
      end

      # === SHOW ===

      test "show returns single post" do
        get api_v1_page_post_url(page_id: @page.id, id: @post1.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @post1.id, json["id"]
        assert_equal @post1.title, json["title"]
        assert_equal @post1.slug, json["slug"]
      end

      test "show returns 404 for non-existent post" do
        get api_v1_page_post_url(page_id: @page.id, id: 999999), headers: @headers
        assert_response :not_found
      end

      test "show returns 404 for post from another page" do
        other_post = posts(:one)
        get api_v1_page_post_url(page_id: @page.id, id: other_post.id), headers: @headers
        assert_response :not_found
      end

      # === CREATE ===

      test "create creates new post" do
        assert_difference("@page.posts.count", 1) do
          post api_v1_page_posts_url(page_id: @page.id),
               params: { post: { title: "New Post", content_html: "<p>Content</p>" } },
               headers: @headers
        end
        assert_response :created

        json = JSON.parse(response.body)
        assert_equal "New Post", json["title"]
        assert_equal "<p>Content</p>", json["content_html"]
        assert json["slug"].present?
      end

      test "create with category" do
        post api_v1_page_posts_url(page_id: @page.id),
             params: { post: { title: "Categorized Post", category_id: @category.id } },
             headers: @headers
        assert_response :created

        json = JSON.parse(response.body)
        assert_equal @category.id, json["category_id"]
      end

      test "create returns validation errors" do
        post api_v1_page_posts_url(page_id: @page.id),
             params: { post: { title: "" } },
             headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json.key?("errors")
        assert_kind_of Array, json["errors"]
      end

      # === UPDATE ===

      test "update updates existing post" do
        patch api_v1_page_post_url(page_id: @page.id, id: @post1.id),
              params: { post: { title: "Updated Title" } },
              headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "Updated Title", json["title"]

        @post1.reload
        assert_equal "Updated Title", @post1.title
      end

      test "update automatically creates a history revision" do
        initial_revision_count = @post1.post_revisions.count

        patch api_v1_page_post_url(page_id: @page.id, id: @post1.id),
              params: { post: { title: "Revised Title" } },
              headers: @headers
        assert_response :success

        @post1.reload
        assert_equal initial_revision_count + 1, @post1.post_revisions.count

        last_revision = @post1.post_revisions.last
        assert_equal "history", last_revision.kind
      end

      test "update allows blank title for draft" do
        # Drafts allow blank titles (validation only on publish)
        patch api_v1_page_post_url(page_id: @page.id, id: @post1.id),
              params: { post: { title: "" } },
              headers: @headers
        assert_response :success
      end

      test "update returns 404 for non-existent post" do
        patch api_v1_page_post_url(page_id: @page.id, id: 999999),
              params: { post: { title: "Test" } },
              headers: @headers
        assert_response :not_found
      end

      # === DESTROY ===

      test "destroy deletes post" do
        assert_difference("@page.posts.count", -1) do
          delete api_v1_page_post_url(page_id: @page.id, id: @post1.id), headers: @headers
        end
        assert_response :no_content
      end

      test "destroy returns 404 for non-existent post" do
        delete api_v1_page_post_url(page_id: @page.id, id: 999999), headers: @headers
        assert_response :not_found
      end

      # === PUBLISH ===

      test "publish publishes a draft post" do
        assert_equal "draft", @post1.status

        post publish_api_v1_page_post_url(page_id: @page.id, id: @post1.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "published", json["status"]
        assert json["first_published_at"].present?

        @post1.reload
        assert_equal "published", @post1.status
      end

      test "publish is idempotent for already published post" do
        post publish_api_v1_page_post_url(page_id: @page.id, id: @post2.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "published", json["status"]
      end

      test "publish with scheduled_at schedules the post" do
        scheduled_time = 1.day.from_now.iso8601

        post publish_api_v1_page_post_url(page_id: @page.id, id: @post1.id),
             params: { scheduled_at: scheduled_time },
             headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "scheduled", json["status"]
        assert json["scheduled_at"].present?
      end

      test "publish with past scheduled_at returns error" do
        past_time = 1.day.ago.iso8601

        post publish_api_v1_page_post_url(page_id: @page.id, id: @post1.id),
             params: { scheduled_at: past_time },
             headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json.key?("error")
      end

      # === AUTHENTICATION ===

      test "returns 401 without auth token" do
        get api_v1_page_posts_url(page_id: @page.id)
        assert_response :unauthorized
      end

      test "returns 401 with invalid token" do
        get api_v1_page_posts_url(page_id: @page.id), headers: { "Authorization" => "Bearer invalid" }
        assert_response :unauthorized
      end

      # === TIPTAP CONVERSION ===

      test "create with HTML auto-converts to JSON" do
        html_content = '<h2>Test Title</h2><p>Test paragraph with <strong>bold</strong> text.</p>'

        post api_v1_page_posts_url(page_id: @page.id),
             params: { post: { title: "HTML Test", content_html: html_content } },
             headers: @headers
        assert_response :created

        json = JSON.parse(response.body)
        assert_equal html_content, json["content_html"]
        assert_not_nil json["content_json"]
        assert_kind_of Hash, json["content_json"]
        assert_equal "doc", json["content_json"]["type"]
        assert json["content_json"]["content"].length > 0
      end

      test "create with JSON auto-converts to HTML" do
        json_content = {
          "type" => "doc",
          "content" => [
            {
              "type" => "heading",
              "attrs" => { "level" => 2 },
              "content" => [{ "type" => "text", "text" => "JSON Title" }]
            },
            {
              "type" => "paragraph",
              "content" => [{ "type" => "text", "text" => "JSON paragraph" }]
            }
          ]
        }

        post api_v1_page_posts_url(page_id: @page.id),
             params: { post: { title: "JSON Test", content_json: json_content } },
             headers: @headers
        assert_response :created

        json = JSON.parse(response.body)
        # Check structure (level might be string due to JSON serialization)
        assert_equal "doc", json["content_json"]["type"]
        assert_equal 2, json["content_json"]["content"].length
        assert_equal "heading", json["content_json"]["content"][0]["type"]
        assert_equal "paragraph", json["content_json"]["content"][1]["type"]
        assert_not_nil json["content_html"]
        assert_kind_of String, json["content_html"]
        assert_includes json["content_html"], "JSON Title"
        assert_includes json["content_html"], "JSON paragraph"
      end

      test "update with HTML updates JSON" do
        new_html = '<p>Updated HTML content</p>'

        patch api_v1_page_post_url(page_id: @page.id, id: @post1.id),
              params: { post: { content_html: new_html, content_json: nil } },
              headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal new_html, json["content_html"]
        assert_not_nil json["content_json"]
        assert_includes json["content_json"].to_s, "Updated HTML content"
      end

      test "update with JSON updates HTML" do
        new_json = {
          "type" => "doc",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [{ "type" => "text", "text" => "Updated JSON content" }]
            }
          ]
        }

        patch api_v1_page_post_url(page_id: @page.id, id: @post1.id),
              params: { post: { content_json: new_json, content_html: nil } },
              headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal new_json, json["content_json"]
        assert_not_nil json["content_html"]
        assert_includes json["content_html"], "Updated JSON content"
      end

      test "create with both HTML and JSON preserves both" do
        html_content = '<p>HTML content</p>'
        json_content = {
          "type" => "doc",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [{ "type" => "text", "text" => "JSON content" }]
            }
          ]
        }

        post api_v1_page_posts_url(page_id: @page.id),
             params: { post: { title: "Both formats", content_html: html_content, content_json: json_content } },
             headers: @headers
        assert_response :created

        json = JSON.parse(response.body)
        assert_equal html_content, json["content_html"]
        assert_equal json_content, json["content_json"]
      end

      test "handles complex HTML structures in conversion" do
        complex_html = <<~HTML
          <h2>Introduction</h2>
          <p>This is a <strong>test</strong> with <em>formatting</em>.</p>
          <ul>
            <li>Item 1</li>
            <li>Item 2</li>
          </ul>
          <p>Check out <a href="https://example.com">this link</a></p>
        HTML

        post api_v1_page_posts_url(page_id: @page.id),
             params: { post: { title: "Complex HTML", content_html: complex_html } },
             headers: @headers
        assert_response :created

        json = JSON.parse(response.body)
        assert_not_nil json["content_json"]
        assert json["content_json"]["content"].length > 1

        # Verify structure includes heading, paragraph, list, etc.
        types = json["content_json"]["content"].map { |c| c["type"] }
        assert_includes types, "heading"
        assert_includes types, "paragraph"
      end

      test "index returns posts with both content formats" do
        # Create a post with HTML that will auto-convert
        @post1.update!(content_html: '<p>Test content</p>', content_json: nil)
        @post1.reload

        get api_v1_page_posts_url(page_id: @page.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        post = json["result"].find { |p| p["id"] == @post1.id }

        assert_not_nil post["content_html"]
        assert_not_nil post["content_json"]
      end
    end
  end
end
