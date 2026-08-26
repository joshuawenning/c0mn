require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "renders a minimal public status page" do
    get rails_health_check_path

    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_select "title", text: "System status | c0mn"
    assert_select "h1", text: "Online"
    assert_select ".health__facts", text: /Local development/
    assert_select ".health__facts", text: /development/
    assert_select "link[rel='stylesheet'][href='/health.css']"
    assert_select "a[href='/']", text: "Return to the collection"
  end

  test "retains the machine-readable JSON response" do
    get rails_health_check_path(format: :json)

    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_equal "up", response.parsed_body.fetch("status")
    assert Time.iso8601(response.parsed_body.fetch("timestamp"))
  end
end
