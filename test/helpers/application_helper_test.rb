require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "renders validated external links" do
    html = external_link_to("Source", "https://example.com/path", class_name: "source-link")

    assert_includes html, 'href="https://example.com/path"'
    assert_includes html, 'class="source-link"'
    assert_includes html, 'target="_blank"'
    assert_includes html, 'rel="noopener"'
  end

  test "renders escaped text instead of unsafe external links" do
    html = external_link_to("<Source>", "javascript:alert('no')")

    assert_equal "&lt;Source&gt;", html
    assert_no_match(/<a|javascript:/i, html)
  end

  test "can require external links to use https" do
    html = external_link_to("Image", "http://example.com/image.jpg", https_only: true)

    assert_equal "Image", html
    assert_no_match(/<a/i, html)
  end

  test "renders and sanitizes Markdown" do
    html = render_markdown("## Heading\n\n**Bold** and [safe](https://example.com).\n\n<script>alert('no')</script>")

    assert_includes html, "<h2>Heading</h2>"
    assert_includes html, "<strong>Bold</strong>"
    assert_includes html, '<a href="https://example.com">safe</a>'
    assert_no_match(/<script/i, html)
  end

  test "rejects unsafe Markdown links" do
    html = render_markdown("[unsafe](javascript:alert('no'))")

    assert_no_match(/javascript:/i, html)
  end
end
