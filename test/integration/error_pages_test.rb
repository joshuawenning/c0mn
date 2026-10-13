require "test_helper"

class ErrorPagesTest < ActionDispatch::IntegrationTest
  test "renders the not found endpoint with a collection destination" do
    get "/404"

    assert_response :not_found
    assert_select "a[href='#{root_path}']"
  end

  test "unknown paths return not found" do
    get "/nowhere-in-the-app"

    assert_response :not_found
  end

  test "error endpoints retain their status codes" do
    [ 422, 500 ].each do |status|
      get "/#{status}"

      assert_response status
    end

    %w[/400.html /406-unsupported-browser.html].each do |path|
      get path
      assert_response :success
    end
  end
end
