require "test_helper"

module API
  module V1
    class AuthorsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @default_user = users(:default_user)
        @default_workspace = workspaces(:default_user_workspace)
        @default_author = authors(:default_user_author)
      end

      test "index returns paginated envelope for authors" do
        token = APIToken.create!(name: "Authors Index Token", user: @default_user, workspace: @default_workspace)

        get api_v1_authors_url, headers: { "Authorization" => "Bearer #{token.token}" }
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json["page"]
        assert_equal 10, json["size"]
        assert_equal 1, json["total"]
        assert_kind_of Array, json["result"]
        assert_equal @default_author.id, json["result"].first["id"]
        refute json["result"].first.key?("member_id")
      end

      test "show returns author" do
        token = APIToken.create!(name: "Authors Show Token", user: @default_user, workspace: @default_workspace)

        get api_v1_author_url(id: @default_author.id), headers: { "Authorization" => "Bearer #{token.token}" }
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @default_author.id, json["id"]
        assert_equal @default_author.email, json["email"]
        refute json.key?("member_id")
      end

      test "create accepts flat payload" do
        user = users(:member_without_blog)
        workspace = workspaces(:one)
        token = APIToken.create!(name: "Authors Create Token", user: user, workspace: workspace)

        assert_difference("Author.count", 1) do
          post api_v1_authors_url,
               params: {
                 first_name: "API",
                 last_name: "Writer",
                 position: "Content Lead",
                 short_description: "Writes via API"
               },
               headers: { "Authorization" => "Bearer #{token.token}" },
               as: :json
        end

        assert_response :created
        json = JSON.parse(response.body)
        assert_equal "API", json["first_name"]
        assert_equal "Writer", json["last_name"]
        assert_equal user.email, json["email"]
        refute json.key?("member_id")
      end

      test "update accepts flat payload" do
        token = APIToken.create!(name: "Authors Update Token", user: @default_user, workspace: @default_workspace)

        patch api_v1_author_url(id: @default_author.id),
              params: {
                position: "Lead Author",
                short_description: "Updated from flat payload"
              },
              headers: { "Authorization" => "Bearer #{token.token}" },
              as: :json

        assert_response :success

        @default_author.reload
        assert_equal "Lead Author", @default_author.position
        assert_equal "Updated from flat payload", @default_author.short_description
      end

      test "destroy deactivates author and filtered index can return inactive authors" do
        token = APIToken.create!(name: "Authors Destroy Token", user: @default_user, workspace: @default_workspace)

        delete api_v1_author_url(id: @default_author.id), headers: { "Authorization" => "Bearer #{token.token}" }
        assert_response :no_content

        @default_author.reload
        assert_not @default_author.active

        get api_v1_authors_url, headers: { "Authorization" => "Bearer #{token.token}" }
        assert_response :success
        active_json = JSON.parse(response.body)
        assert_equal 0, active_json["total"]

        get api_v1_authors_url,
            params: { active: false },
            headers: { "Authorization" => "Bearer #{token.token}" }
        assert_response :success

        inactive_json = JSON.parse(response.body)
        ids = inactive_json["result"].map { |a| a["id"] }
        assert_includes ids, @default_author.id
      end
    end
  end
end
