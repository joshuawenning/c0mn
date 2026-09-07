require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "renders the public about page and links to process liveness" do
    get about_path

    assert_response :success
    assert_select "title", text: "About | c0mn"
    assert_select "h1", text: "The URL is the raw material."
    assert_select ".about-process__steps li", count: 3
    assert_select ".about-system__table tbody tr", count: 6
    assert_select ".about-system__table", text: /Hetzner Cloud \/ AMD64/
    assert_select ".about-system__table", text: /Process liveness/
    assert_select ".about-system__table", text: /External dependencies are not checked/
    assert_select "a[href='#{rails_health_check_path}']", text: "View liveness check"
    assert_select "time", text: /Checked/, count: 0
    assert_select "a.site-nav__link--active[aria-current='page'][href='#{about_path}']", text: "About"
    assert_select "a[href='#{admin_root_path}']", count: 0
  end
end
