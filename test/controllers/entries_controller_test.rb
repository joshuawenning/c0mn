require "test_helper"
require_relative "../test_helpers/image_import_test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
  include ImageImportTestHelper
  test "renders the public collection" do
    entry = create_entry!(title: "A house in Mallorca", url: "https://example.com/house.jpg", tag_list: "architecture")

    get root_path

    assert_response :success
    assert_select "html[lang='en']"
    assert_select "meta[charset='utf-8']"
    skip_targets = css_select("a[href^='#']").filter_map do |link|
      css_select("[id='#{link['href'].delete_prefix('#')}'][tabindex='-1']").first
    end
    assert_not_empty skip_targets
    assert_rendered_entries entry
    assert_select "img[src='#{entry.url}']", count: 0
    assert_select "a[href='#{admin_root_path}']", count: 0
    assert_select "a[href='#{about_path}']"
  end

  test "shows admin navigation only to a signed-in administrator" do
    sign_in_as users(:owner)

    get root_path

    assert_response :success
    assert_select "a[href='#{admin_root_path}']"
  end

  test "filters by tag" do
    house = create_entry!(title: "A house", url: "https://example.com/house", tag_list: "architecture")
    create_entry!(title: "A song", url: "https://example.com/song", tag_list: "music")

    get root_path(tag: "architecture")

    assert_response :success
    assert_rendered_entries house
    assert_select "a[href='#{root_path(tag: 'architecture')}'][aria-current='page']"
  end

  test "offers an entry creation destination for empty results" do
    sign_in_as users(:owner)
    Entry.create!(title: "Existing", url: "https://example.com/existing")

    get root_path(q: "missing")
    assert_response :success
    assert_rendered_entries
    assert_select "a[href='#{new_admin_entry_path}']"

    Entry.delete_all
    get root_path
    assert_response :success
    assert_rendered_entries
    assert_select "a[href='#{new_admin_entry_path}']"
  end

  test "searches within a different tag while filtering" do
    house = create_entry!(title: "A house", url: "https://example.com/house", tag_list: "architecture, music")

    get root_path(tag: "architecture", q: "music")

    assert_response :success
    assert_rendered_entries house
  end

  test "limits search input before querying" do
    query = "x" * (EntriesController::MAX_QUERY_LENGTH + 50)

    get root_path(q: query)

    assert_response :success
    assert_select "input[name='q'][maxlength='#{EntriesController::MAX_QUERY_LENGTH}'][value='#{query.first(EntriesController::MAX_QUERY_LENGTH)}']"
  end

  test "clamps collection pages to the available range" do
    entries = (EntriesController::PAGE_SIZE + 1).times.map do |index|
      Entry.create!(title: "Entry #{index}", url: "https://example.com/page-#{index}")
    end

    get root_path(page: 10_000)

    assert_response :success
    assert_rendered_entries entries.first
    assert_select "a[href='#{root_path(page: 1)}']"
    assert_select "a[href='#{root_path(page: 3)}']", count: 0
  end

  test "loads tags in a bounded number of queries across a full collection page" do
    entries = [ create_entry!(title: "First", url: "https://example.com/first", tag_list: "shared, reference") ]
    first_page_queries = collection_queries { get root_path }

    (EntriesController::PAGE_SIZE - 1).times do |index|
      entries << create_entry!(title: "Entry #{index}", url: "https://example.com/loading-#{index}", tag_list: "shared, reference")
    end
    full_page_queries = collection_queries { get root_path }

    assert_response :success
    assert_rendered_entries(*entries)
    assert_equal first_page_queries.size, full_page_queries.size
    assert_equal 1, full_page_queries.count { |query| query.include?('FROM "taggings"') }
    assert_equal 2, full_page_queries.count { |query| query.include?('FROM "tags"') }
    assert_equal 1, full_page_queries.count { |query| query.include?('COUNT(*) FROM "entries"') }
    assert_empty full_page_queries.grep(/SELECT 1 AS one FROM "entries"/)
  end

  test "treats malformed collection filters as absent" do
    entry = Entry.create!(title: "Visible", url: "https://example.com/visible")

    [ { page: [ "2" ] }, { page: { value: "2" } }, { q: { value: "missing" }, tag: [ "missing" ] },
      { page: "abc" }, { page: "0" }, { page: "-2" } ].each do |filters|
      get root_path, params: filters

      assert_response :success
      assert_rendered_entries entry
    end
  end

  test "preserves search and tag filters across pagination" do
    (EntriesController::PAGE_SIZE + 1).times do |index|
      create_entry!(title: "House #{index}", url: "https://example.com/filter-#{index}", tag_list: "architecture")
    end

    get root_path(q: "House", tag: "architecture")

    assert_response :success
    assert_select "a[href='#{root_path(q: 'House', tag: 'architecture', page: 2)}']"
  end

  test "includes a content security policy" do
    get root_path

    policy = response.headers["Content-Security-Policy"]
    assert_includes policy, "base-uri 'self'"
    assert_includes policy, "form-action 'self'"
    assert_includes policy, "frame-ancestors 'none'"
    assert_includes policy, "frame-src 'self' https://www.youtube.com"
    assert_includes policy, "object-src 'none'"
  end

  test "renders optimized local previews and keeps the source link" do
    entry = Entry.create!(title: "Image", url: "https://example.com/image.jpg")
    import_image(entry)

    get root_path

    assert_response :success
    assert_select "img[src*='/rails/active_storage/'][width='640'][height='320'][decoding='async']"
    assert_select "img[src='#{entry.url}']", count: 0
    get entry_path(entry)
    assert_response :success
    assert_select "img[srcset][sizes][width='800']"
    assert_select "a[href='#{entry.url}']"
  end

  test "only embeds videos on the entry detail page" do
    entry = Entry.create!(title: "Video", url: "https://youtube.com/watch?v=dQw4w9WgXcQ")

    get root_path
    assert_response :success
    assert_select "iframe", count: 0

    get entry_path(entry)
    assert_response :success
    assert_select "iframe[src='https://www.youtube.com/embed/dQw4w9WgXcQ'][title='Video']", count: 1
  end

  test "does not link unsafe values from legacy records" do
    entry = Entry.create!(title: "Legacy", url: "https://example.com/legacy")
    entry.update_column(:url, "javascript:alert('no')")

    get entry_path(entry)

    assert_response :success
    assert_select "a[href^='javascript:']", count: 0
  end

  test "serves the local stylesheets linked by the collection" do
    get root_path
    assert_response :success
    stylesheets = css_select("link[rel='stylesheet'][href^='/']").map { |link| link["href"] }.uniq
    assert_not_empty stylesheets

    stylesheets.each do |stylesheet|
      get stylesheet
      assert_response :success
      assert_equal "text/css", response.media_type
    end
  end

  test "renders entry notes as sanitized Markdown" do
    entry = create_entry!(
      title: "Notes",
      url: "https://example.com/notes",
      notes: "# Context\n\nA **useful** note. <script>alert('no')</script>",
      tag_list: "reference"
    )

    get entry_path(entry)

    assert_response :success
    assert_includes response.body, "Context"
    assert_select "strong", text: "useful"
    assert_select "script", text: /alert\('no'\)/, count: 0
    assert_select "a[href='#{entry.url}'][target='_blank'][rel='noopener']"
  end

  private
    def assert_rendered_entries(*entries)
      paths = css_select("a[href]").map { |link| link["href"] }.grep(%r{\A/entries/\d+\z}).uniq.sort
      assert_equal entries.map { |entry| entry_path(entry) }.sort, paths
    end

    def collection_queries
      queries = []
      subscriber = ->(_name, _start, _finish, _id, payload) {
        queries << payload[:sql] if payload[:sql].match?(/\ASELECT/i) && !payload[:cached] && payload[:name] != "SCHEMA"
      }

      ActiveRecord::Base.uncached do
        ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { yield }
      end

      queries
    end
end
