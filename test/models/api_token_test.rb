require "test_helper"

class APITokenTest < ActiveSupport::TestCase
  setup do
    @user = users(:default_user)
    @workspace = workspaces(:default_user_workspace)
  end

  test "should be valid with valid attributes" do
    api_token = APIToken.new(name: "Test Token", user: @user, workspace: @workspace)
    assert api_token.valid?
  end

  test "should require a name" do
    api_token = APIToken.new(user: @user, workspace: @workspace)
    assert_not api_token.valid?
    assert_includes api_token.errors[:name], "can't be blank"
  end

  test "should generate a token on creation" do
    api_token = APIToken.create!(name: "Test Token", user: @user, workspace: @workspace)
    assert_not_nil api_token.token
  end
end
