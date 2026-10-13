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

  test "renders escaped text instead of https script resources" do
    html = external_link_to("Source", "https://example.com/application.js")

    assert_equal "Source", html
    assert_no_match(/<a/i, html)
  end

  test "can require external links to use https" do
    html = external_link_to("Image", "http://example.com/image.jpg", https_only: true)

    assert_equal "Image", html
    assert_no_match(/<a/i, html)
  end

  test "renders and sanitizes Markdown" do
    html = render_markdown("# Heading\n\n**Bold** and [safe](https://example.com).\n\n<script>alert('no')</script>")

    assert_includes html, "<h2>Heading</h2>"
    assert_includes html, "<strong>Bold</strong>"
    assert_includes html, '<a href="https://example.com">safe</a>'
    assert_no_match(/<script/i, html)
  end

  test "shifts Markdown headings while keeping h1 reserved" do
    html = render_markdown(<<~MARKDOWN)
      # Level one
      ## Level two
      ### Level three
      #### Level four
      ##### Level five
      ###### Level six
    MARKDOWN

    assert_includes html, "<h2>Level one</h2>"
    assert_includes html, "<h3>Level two</h3>"
    assert_includes html, "<h4>Level three</h4>"
    assert_includes html, "<h5>Level four</h5>"
    assert_includes html, "<h6>Level five</h6>"
    assert_includes html, "<h6>Level six</h6>"
    assert_no_match(/<h1[ >]/i, html)
  end

  test "builds a plain text Markdown excerpt without raw HTML or link destinations" do
    excerpt = markdown_excerpt(<<~MARKDOWN)
      # Heading

      A **useful** note with a [link](https://example.com).

      <script>alert('no')</script>

      - One
      - Two
    MARKDOWN

    assert_equal "Heading A useful note with a link. One Two", excerpt
    assert_no_match(/<|https:|alert/, excerpt)
  end

  test "truncates Markdown excerpts" do
    assert_equal "A long...", markdown_excerpt("A long sentence", length: 9)
  end

  test "cached excerpts preserve Markdown text and truncation boundaries" do
    notes = "# Héading\n\nA **useful** [link](https://example.com).\n\n- First\n- Second\n\n```ruby\nputs 'code'\n```\n\n<script>hidden</script>"
    entry = Entry.create!(title: "Notes", url: "https://example.com/cached", notes: notes)

    with_memory_cache do
      [ 3, 9, 40, 150 ].each do |length|
        expected = markdown_excerpt(notes, length: length)
        assert_equal expected, entry_notes_excerpts([ entry ], length: length).fetch(entry.id)
        assert_equal expected, entry_notes_excerpts([ entry ], length: length).fetch(entry.id)
      end
    end
  end

  test "batches excerpt caching and invalidates edited notes" do
    first = Entry.create!(title: "First", url: "https://example.com/first", notes: "First **note**")
    second = Entry.create!(title: "Second", url: "https://example.com/second", notes: "Second note")
    blank = Entry.create!(title: "Blank", url: "https://example.com/blank")

    with_memory_cache do
      writes = []
      subscriber = ->(_name, _start, _finish, _id, payload) { writes << payload }
      ActiveSupport::Notifications.subscribed(subscriber, "cache_write_multi.active_support") do
        2.times do
          assert_equal({ first.id => "First note", second.id => "Second note" }, entry_notes_excerpts([ first, second, blank ]))
        end
      end
      assert_equal 1, writes.size

      travel 1.second do
        first.update!(notes: "Updated **note**")
      end
      assert_equal "Updated note", entry_notes_excerpts([ first, second ]).fetch(first.id)

      second.update!(notes: "")
      assert_not entry_notes_excerpts([ first, second ]).key?(second.id)
    end
  end

  test "rejects unsafe Markdown links" do
    html = render_markdown("[unsafe](javascript:alert('no'))")

    assert_no_match(/javascript:/i, html)
  end

  private
    def with_memory_cache
      original = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      yield
    ensure
      Rails.cache = original
    end
end
