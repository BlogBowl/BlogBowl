require "test_helper"

module API
  module V1
    class ImagesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:default_user)
        @workspace = workspaces(:default_user_workspace)

        @token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
        @headers = { "Authorization" => "Bearer #{@token.token}" }

        @image_file = fixture_file_upload("webplogo.webp", "image/webp")
      end

      # === UPLOAD ===

      test "upload returns image url" do
        post upload_api_v1_images_url,
             params: { file: @image_file },
             headers: @headers
        assert_response :created

        json = JSON.parse(response.body)
        assert json.key?("url")
        assert json["url"].present?
      end

      test "upload returns error without file" do
        post upload_api_v1_images_url, headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json.key?("error")
      end

      # === AUTHENTICATION ===

      test "returns 401 without auth token" do
        post upload_api_v1_images_url, params: { file: @image_file }
        assert_response :unauthorized
      end

      test "returns 401 with invalid token" do
        post upload_api_v1_images_url,
             params: { file: @image_file },
             headers: { "Authorization" => "Bearer invalid" }
        assert_response :unauthorized
      end
    end
  end
end
