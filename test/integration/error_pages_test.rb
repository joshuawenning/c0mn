require "test_helper"

class ErrorPagesTest < ActionDispatch::IntegrationTest
  test "renders the branded not found endpoint" do
    get "/404"

    assert_response :not_found
    assert_select "title", text: "Page not found | c0mn"
    assert_select "h1", text: "Nothing collected here."
    assert_select "a.site-header__wordmark", text: "c0mn"
    assert_select ".not-found__wordmark", count: 0
    assert_select "a[href='/']", text: "Return to the collection"
  end

  test "routes unknown paths through the branded not found page" do
    get "/nowhere-in-the-app"

    assert_response :not_found
    assert_select "title", text: "Page not found | c0mn"
    assert_select "h1", text: "Nothing collected here."
  end
end
