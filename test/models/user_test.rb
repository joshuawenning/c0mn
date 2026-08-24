require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ", username: "owner")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "normalizes and validates usernames" do
    user = User.new(email_address: "new@example.com", username: " New-Owner ", password: "a secure password")

    assert user.valid?
    assert_equal "new-owner", user.username

    user.username = "not allowed!"
    assert_not user.valid?
  end
end
