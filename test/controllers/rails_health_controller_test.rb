require "test_helper"

class RailsHealthControllerTest < ActionDispatch::IntegrationTest
  test "serves the standard deployment health check" do
    get rails_health_check_path

    assert_response :success
    assert_equal "rails/health", Rails.application.routes.recognize_path(rails_health_check_path)[:controller]
  end
end
