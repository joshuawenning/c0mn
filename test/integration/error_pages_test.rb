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

  test "static error pages use independently versioned Inter assets" do
    [ 422, 500 ].each do |status|
      get "/#{status}"

      assert_response status
      assert_select "link[href='/inter-v4.1.css']"
    end

    %w[/400.html /406-unsupported-browser.html].each do |path|
      get path
      assert_response :success
      assert_select "link[href='/inter-v4.1.css']"
    end

    get "/inter-v4.1.css"
    assert_response :success
    font_urls = response.body.scan(/url\(["']?([^"')]+\.woff2)/).flatten
    assert_equal 2, font_urls.size
    font_urls.each do |url|
      get url

      assert_response :success
      assert_equal "wOF2", response.body.byteslice(0, 4)
    end
  end
end
