require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should not create a workspace when skip_workspace_creation is true" do
    user = User.create(
      email: "skip_workspace@example.com",
      password: "Secret 1*3*5*",
      skip_workspace_creation: true
    )
    assert user.persisted?
    assert_empty user.workspaces
  end
end
