require "test_helper"

module API
  module V1
    class MiscControllerTest < ActionDispatch::IntegrationTest
      SPEC_PATH = Rails.root.join("doc", "apidoc", "schema_swagger_json.json")

      setup do
        host! "example.com"
      end

      test "openapi returns the spec without authentication" do
        get "/api/v1/misc/openapi.json"
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "BlogBowl API", json["info"]["title"]
        assert json["paths"].present?
      end

      test "openapi does not require auth token" do
        get "/api/v1/misc/openapi.json"
        assert_response :success
      end

      test "openapi returns 404 when spec file is missing" do
        SPEC_PATH.rename("#{SPEC_PATH}.bak") if SPEC_PATH.exist?

        get "/api/v1/misc/openapi.json"
        assert_response :not_found

        json = JSON.parse(response.body)
        assert json["error"].present?
      ensure
        File.rename("#{SPEC_PATH}.bak", SPEC_PATH) if File.exist?("#{SPEC_PATH}.bak")
      end
    end
  end
end
