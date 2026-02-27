require "test_helper"

module API
  module V1
    class CategoriesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:default_user)
        @workspace = workspaces(:default_user_workspace)
        @page = pages(:default_user_page_1)
        @category1 = categories(:default_user_category_1)
        @category2 = categories(:default_user_category_2)

        @token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
        @headers = { "Authorization" => "Bearer #{@token.token}" }
      end

      # === INDEX (List) ===

      test "index returns paginated envelope" do
        get api_v1_page_categories_url(page_id: @page.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["page"]
        assert_equal 10, json["size"]
        assert_equal 2, json["total"]
        assert_kind_of Array, json["result"]
        assert_equal 2, json["result"].length
      end

      test "index respects size parameter" do
        get api_v1_page_categories_url(page_id: @page.id), params: { size: 1 }, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["size"]
        assert_equal 1, json["result"].length
      end

      test "index returns correct category fields" do
        get api_v1_page_categories_url(page_id: @page.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        category = json["result"].first

        assert category.key?("id")
        assert category.key?("name")
        assert category.key?("slug")
        assert category.key?("description")
        assert category.key?("color")
        assert category.key?("page_id")
        assert category.key?("created_at")
        assert category.key?("updated_at")
      end

      test "index returns 404 for non-existent page" do
        get api_v1_page_categories_url(page_id: 999999), headers: @headers
        assert_response :not_found
      end

      # === SHOW ===

      test "show returns single category" do
        get api_v1_page_category_url(page_id: @page.id, id: @category1.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @category1.id, json["id"]
        assert_equal @category1.name, json["name"]
        assert_equal @category1.slug, json["slug"]
      end

      test "show returns 404 for non-existent category" do
        get api_v1_page_category_url(page_id: @page.id, id: 999999), headers: @headers
        assert_response :not_found
      end

      test "show returns 404 for category from another page" do
        other_category = categories(:one)
        get api_v1_page_category_url(page_id: @page.id, id: other_category.id), headers: @headers
        assert_response :not_found
      end

      # === CREATE ===

      test "create creates new category" do
        assert_difference("@page.categories.count", 1) do
          post api_v1_page_categories_url(page_id: @page.id),
               params: { category: { name: "New Category", description: "A new category" } },
               headers: @headers
        end
        assert_response :created

        json = JSON.parse(response.body)
        assert_equal "New Category", json["name"]
        assert_equal "A new category", json["description"]
        assert json["slug"].present?
      end

      test "create returns validation errors" do
        post api_v1_page_categories_url(page_id: @page.id),
             params: { category: { name: "" } },
             headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json.key?("errors")
        assert_kind_of Array, json["errors"]
      end

      # === UPDATE ===

      test "update updates existing category" do
        patch api_v1_page_category_url(page_id: @page.id, id: @category1.id),
              params: { category: { name: "Updated Name" } },
              headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "Updated Name", json["name"]

        @category1.reload
        assert_equal "Updated Name", @category1.name
      end

      test "update returns validation errors" do
        patch api_v1_page_category_url(page_id: @page.id, id: @category1.id),
              params: { category: { name: "" } },
              headers: @headers
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json.key?("errors")
      end

      test "update returns 404 for non-existent category" do
        patch api_v1_page_category_url(page_id: @page.id, id: 999999),
              params: { category: { name: "Test" } },
              headers: @headers
        assert_response :not_found
      end

      # === DESTROY ===

      test "destroy deletes category" do
        assert_difference("@page.categories.count", -1) do
          delete api_v1_page_category_url(page_id: @page.id, id: @category1.id), headers: @headers
        end
        assert_response :no_content
      end

      test "destroy returns 404 for non-existent category" do
        delete api_v1_page_category_url(page_id: @page.id, id: 999999), headers: @headers
        assert_response :not_found
      end

      # === AUTHENTICATION ===

      test "returns 401 without auth token" do
        get api_v1_page_categories_url(page_id: @page.id)
        assert_response :unauthorized
      end

      test "returns 401 with invalid token" do
        get api_v1_page_categories_url(page_id: @page.id), headers: { "Authorization" => "Bearer invalid" }
        assert_response :unauthorized
      end
    end
  end
end
