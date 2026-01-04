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
    end
  end
end
