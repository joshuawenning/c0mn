require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:owner) }

  test "new" do
    get new_session_path
    assert_response :success
    assert_select "h1", text: "Sign in"
    assert_select "a[href='#{admin_root_path}']", count: 0
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: " #{@user.email_address.upcase} ", password: "a secure password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(@user)

    delete logout_path

    assert_redirected_to root_path
    assert_empty cookies[:session_id]
  end

  test "returns the owner to a protected admin page after login" do
    get admin_entries_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "a secure password" }

    assert_redirected_to admin_entries_url
  end
end
