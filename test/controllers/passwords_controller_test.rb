require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "reset link is invalid"
  end

  test "edit with expired password reset token" do
    token = @user.password_reset_token

    travel @user.password_reset_token_expires_in + 1.second do
      get edit_password_path(token)
    end

    assert_redirected_to new_password_path
  end

  test "edit with a token for a deleted user" do
    token = @user.password_reset_token
    @user.destroy!

    get edit_password_path(token)

    assert_redirected_to new_password_path
  end

  test "update" do
    @user.sessions.create!(user_agent: "First browser", ip_address: "192.0.2.1")
    @user.sessions.create!(user_agent: "Second browser", ip_address: "192.0.2.2")

    assert_changes -> { @user.reload.password_digest } do
      assert_difference -> { @user.sessions.count }, -2 do
        put password_path(@user.password_reset_token), params: {
          password: "new secure password",
          password_confirmation: "new secure password"
        }
      end
      assert_redirected_to new_session_path
    end

    follow_redirect!
    assert_notice "Password has been reset"
    assert_select ".flash[role='status'][aria-live='polite'][aria-atomic='true']"
  end

  test "a reset token cannot be reused after the password changes" do
    token = @user.password_reset_token

    put password_path(token), params: {
      password: "new secure password",
      password_confirmation: "new secure password"
    }
    put password_path(token), params: {
      password: "new secure password",
      password_confirmation: "new secure password"
    }

    assert_redirected_to new_password_path
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "a secure password", password_confirmation: "does not match" }
      assert_response :unprocessable_entity
    end

    assert_select "[role='alert']", /confirmation doesn't match/
    assert_select "input[aria-invalid='true'][aria-describedby='password-reset-errors']"
  end

  test "update with a blank password" do
    token = @user.password_reset_token

    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "", password_confirmation: "" }
      assert_response :unprocessable_entity
    end

    assert_select "[role='alert']", /Password can't be blank/
  end

  test "update with a short password" do
    token = @user.password_reset_token

    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "too short", password_confirmation: "too short" }
      assert_response :unprocessable_entity
    end

    assert_select "[role='alert']", /Password is too short/
  end

  private
    def assert_notice(text)
      assert_select ".flash", /#{text}/
    end
end
