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

  test "rolls back a password reset when session revocation fails" do
    user = users(:owner)
    original_digest = user.password_digest
    sessions = user.sessions
    sessions.define_singleton_method(:delete_all) do
      raise ActiveRecord::StatementInvalid, "database unavailable"
    end

    assert_raises ActiveRecord::StatementInvalid do
      user.reset_password(password: "new secure password", password_confirmation: "new secure password")
    end

    assert_equal original_digest, user.reload.password_digest
  end
end
