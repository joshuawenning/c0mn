require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:owner) }

  test "new" do
    get new_session_path
    assert_response :success
    assert_select "h1", text: "Sign in"
    assert_select "a[href='#{admin_root_path}']", count: 0
    assert_select ".form-field .form-control", count: 2
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

    follow_redirect!
    assert_select ".flash[role='alert'][aria-atomic='true']", /Try another email address or password/
  end

  test "destroy" do
    sign_in_as(@user)

    delete logout_path

    assert_redirected_to root_path
    assert_empty cookies[:session_id]
  end

  test "returns an administrator to a protected admin page after login" do
    get admin_entries_path(filter: "recent")
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "a secure password" }

    assert_redirected_to admin_entries_url(filter: "recent")
  end

  test "does not retain the request host in the return path" do
    get admin_entries_path, headers: { "X-Forwarded-Host" => "attacker.example" }
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "a secure password" }

    assert_redirected_to admin_entries_url
  end

  test "does not return to a protected mutation after login" do
    post admin_entries_path, params: { entry: { title: "Not created", url: "https://example.com/entry" } }
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "a secure password" }

    assert_redirected_to root_path
    assert_not Entry.exists?(title: "Not created")
  end

  test "can return to a protected head request after login" do
    head admin_entries_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "a secure password" }

    assert_redirected_to admin_entries_url
  end
end
