require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "renders the public about page" do
    get about_path

    assert_response :success
    assert_select "a[aria-current='page'][href='#{about_path}']"
    assert_select "a[href='#{admin_root_path}']", count: 0
  end
end
