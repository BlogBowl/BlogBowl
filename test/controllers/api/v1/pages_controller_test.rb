require "test_helper"

module API
  module V1
    class PagesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:default_user)
        @workspace = workspaces(:default_user_workspace)
        @page1 = pages(:default_user_page_1)
        @page2 = pages(:default_user_page_2)

        @token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
        @headers = { "Authorization" => "Bearer #{@token.token}" }

        # Set base domain for page creation tests
        ENV['PAGES_BASE_DOMAIN'] = 'blogbowl.test'
      end

      teardown do
        ENV.delete('PAGES_BASE_DOMAIN')
      end

      # === INDEX (List) ===

      test "index returns paginated envelope" do
        get api_v1_pages_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["page"]
        assert_equal 10, json["size"]
        assert_equal 2, json["total"]
        assert_kind_of Array, json["result"]
        assert_equal 2, json["result"].length
      end

      test "index respects page parameter" do
        # Create more pages to test pagination
        8.times { |i| @workspace.pages.create!(name: "Extra Page #{i}", slug: "extra-page-#{i}") }

        get api_v1_pages_url, params: { page: 2, size: 5 }, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 2, json["page"]
        assert_equal 5, json["size"]
        assert_equal 10, json["total"]
        assert_equal 5, json["result"].length
      end

      test "index respects size parameter" do
        get api_v1_pages_url, params: { size: 1 }, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["size"]
        assert_equal 1, json["result"].length
      end

      test "index limits size to max 100" do
        get api_v1_pages_url, params: { size: 200 }, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 100, json["size"]
      end

      test "index returns correct page fields" do
        get api_v1_pages_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        page = json["result"].first

        assert page.key?("id")
        assert page.key?("name")
        assert page.key?("slug")
        assert page.key?("name_slug")
        assert page.key?("domain")
        assert page.key?("workspace_id")
        assert page.key?("created_at")
        assert page.key?("updated_at")
      end

      # === SHOW ===

      test "show returns single page" do
        get api_v1_page_url(id: @page1.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @page1.id, json["id"]
        assert_equal @page1.name, json["name"]
        assert_equal @page1.slug, json["slug"]
      end

      test "show returns 404 for non-existent page" do
        get api_v1_page_url(id: 999999), headers: @headers
        assert_response :not_found
      end

      test "show returns 404 for page from another workspace" do
        other_page = pages(:one)
        get api_v1_page_url(other_page), headers: @headers
        assert_response :not_found
      end

      # === CREATE ===

      test "create creates new page" do
        assert_difference("@workspace.pages.count", 1) do
          post api_v1_pages_url, params: { page: { name: "New Page", slug: "new-page" } }, headers: @headers
        end
        assert_response :created

        json = JSON.parse(response.body)
        assert_equal "New Page", json["name"]
        assert_equal "new-page", json["slug"]
      end

      test "create returns validation errors" do
        post api_v1_pages_url, params: { page: { name: "" } }, headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json.key?("errors")
        assert_kind_of Array, json["errors"]
      end

      # === UPDATE ===

      test "update updates existing page" do
        patch api_v1_page_url(id: @page1.id), params: { page: { name: "Updated Name" } }, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "Updated Name", json["name"]

        @page1.reload
        assert_equal "Updated Name", @page1.name
      end

      test "update returns validation errors" do
        patch api_v1_page_url(id: @page1.id), params: { page: { name: "" } }, headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json.key?("errors")
      end

      test "update returns 404 for non-existent page" do
        patch api_v1_page_url(id: 999999), params: { page: { name: "Test" } }, headers: @headers
        assert_response :not_found
      end
    end
  end
end
