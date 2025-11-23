require "test_helper"

class Settings::APITokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lazaro_nixon)
    @workspace = workspaces(:one)
    sign_in_as(@user)
  end

  test "should get index" do
    get settings_api_tokens_url
    assert_response :success
  end

  test "should create api_token" do
    assert_difference("APIToken.count") do
      post settings_api_tokens_url, params: { api_token: { name: "New Token" } }
    end

    assert_redirected_to settings_api_tokens_url
    assert_equal "API token was created successfully.", flash[:notice]
  end

  test "should destroy api_token" do
    api_token = APIToken.create!(name: "Delete Me", user: @user, workspace: @workspace)
    assert_difference("APIToken.count", -1) do
      delete settings_api_token_url(api_token)
    end

    assert_redirected_to settings_api_tokens_url
    assert_equal "API token was deleted successfully.", flash[:notice]
  end
end
