require "test_helper"

module API
  module V1
    class ImagesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:default_user)
        @workspace = workspaces(:default_user_workspace)
        @page = pages(:default_user_page_1)
        @post = posts(:default_user_post_1)

        @token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
        @headers = { "Authorization" => "Bearer #{@token.token}" }

        @image_file = fixture_file_upload("webplogo.webp", "image/webp")
      end

      # === SHOW ===

      test "show returns 404 when no cover image attached" do
        get api_v1_page_post_cover_image_url(page_id: @page.id, post_id: @post.id), headers: @headers
        assert_response :not_found

        json = JSON.parse(response.body)
        assert json.key?("error")
      end

      test "show returns cover image url when attached" do
        @post.cover_image.attach(
          io: File.open(Rails.root.join("test/fixtures/files/webplogo.webp")),
          filename: "cover.webp",
          content_type: "image/webp"
        )

        get api_v1_page_post_cover_image_url(page_id: @page.id, post_id: @post.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert json.key?("url")
        assert json["url"].present?
      end

      # === CREATE ===

      test "create uploads cover image" do
        post api_v1_page_post_cover_image_url(page_id: @page.id, post_id: @post.id),
             params: { file: @image_file },
             headers: @headers
        assert_response :created

        json = JSON.parse(response.body)
        assert json.key?("url")
        assert json["url"].present?

        @post.reload
        assert @post.cover_image.attached?
      end

      test "create returns error without file" do
        post api_v1_page_post_cover_image_url(page_id: @page.id, post_id: @post.id),
             headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert_equal "File is required", json["error"]
      end

      # === UPDATE ===

      test "update replaces cover image" do
        @post.cover_image.attach(
          io: File.open(Rails.root.join("test/fixtures/files/webplogo.webp")),
          filename: "old-cover.webp",
          content_type: "image/webp"
        )

        new_file = fixture_file_upload("webplogo.webp", "image/webp")
        patch api_v1_page_post_cover_image_url(page_id: @page.id, post_id: @post.id),
              params: { file: new_file },
              headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert json.key?("url")
        assert json["url"].present?
      end

      test "update returns error without file" do
        patch api_v1_page_post_cover_image_url(page_id: @page.id, post_id: @post.id),
              headers: @headers
        assert_response :unprocessable_entity
      end

      # === DESTROY ===

      test "destroy removes cover image" do
        @post.cover_image.attach(
          io: File.open(Rails.root.join("test/fixtures/files/webplogo.webp")),
          filename: "cover.webp",
          content_type: "image/webp"
        )

        delete api_v1_page_post_cover_image_url(page_id: @page.id, post_id: @post.id),
               headers: @headers
        assert_response :no_content

        @post.reload
        assert_not @post.cover_image.attached?
      end

      test "destroy returns 404 when no cover image" do
        delete api_v1_page_post_cover_image_url(page_id: @page.id, post_id: @post.id),
               headers: @headers
        assert_response :not_found
      end

      # === ERROR CASES ===

      test "returns 404 for non-existent post" do
        get api_v1_page_post_cover_image_url(page_id: @page.id, post_id: 999999), headers: @headers
        assert_response :not_found
      end

      test "returns 404 for non-existent page" do
        get api_v1_page_post_cover_image_url(page_id: 999999, post_id: @post.id), headers: @headers
        assert_response :not_found
      end

      # === AUTHENTICATION ===

      test "returns 401 without auth token" do
        get api_v1_page_post_cover_image_url(page_id: @page.id, post_id: @post.id)
        assert_response :unauthorized
      end

      test "returns 401 with invalid token" do
        get api_v1_page_post_cover_image_url(page_id: @page.id, post_id: @post.id),
            headers: { "Authorization" => "Bearer invalid" }
        assert_response :unauthorized
      end
    end
  end
end
