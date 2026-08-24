require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
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
