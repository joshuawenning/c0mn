require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "renders a minimal public status page" do
    get rails_health_check_path

    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_select "title", text: "Application liveness | c0mn"
    assert_select "h1", text: "Process online"
    assert_select ".health__summary", text: /External dependencies are not checked/
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

class HealthControllerFailureTest < ActionController::TestCase
  tests HealthController

  test "reports normal application failures" do
    @controller.define_singleton_method(:architecture) { raise "unavailable" }

    get :show

    assert_response :internal_server_error
    assert_equal "down", response.body
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_not_includes HealthController.rescue_handlers.map(&:first), "Exception"
  end

  test "does not rescue fatal exceptions" do
    @controller.define_singleton_method(:architecture) { raise Interrupt }

    assert_raises(Interrupt) { get :show }
  end
end
