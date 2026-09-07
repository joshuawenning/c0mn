require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
  test "renders the public collection" do
    create_entry!(title: "A house in Mallorca", url: "https://example.com/house.jpg", tag_list: "architecture")

    get root_path

    assert_response :success
    assert_select "h1.archive-header__title a", text: "c0mn"
    assert_select "form.archive-search"
    assert_select ".tag-nav__item"
    assert_select ".tag-dot circle[fill^='#']"
    assert_select ".entry-card", 1
    assert_select ".entry-card__media img"
    assert_select "a[href='#{admin_root_path}']", count: 0
    assert_select "a[href='#{about_path}']", text: "About"
    assert_select ".site-footer__copyright", text: "c0mn © #{Date.current.year}"
    assert_select ".site-footer__credit a[href='https://joshuawenning.com/']", text: "@joshuawenning"
    assert_select ".site-footer__source[href='https://github.com/joshuawenning/c0mn']", text: "View Source"
  end

  test "shows admin navigation only to a signed-in administrator" do
    sign_in_as users(:owner)

    get root_path

    assert_response :success
    assert_select "a[href='#{admin_root_path}']", text: "Admin"
  end

  test "filters by tag" do
    create_entry!(title: "A house", url: "https://example.com/house", tag_list: "architecture")
    create_entry!(title: "A song", url: "https://example.com/song", tag_list: "music")

    get root_path(tag: "architecture")

    assert_response :success
    assert_includes response.body, "A house"
    assert_not_includes response.body, "A song"
  end

  test "searches within a different tag while filtering" do
    create_entry!(title: "A house", url: "https://example.com/house", tag_list: "architecture, music")

    get root_path(tag: "architecture", q: "music")

    assert_response :success
    assert_includes response.body, "A house"
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

  test "renders remote images without sending a referrer" do
    Entry.create!(title: "Image", url: "https://example.com/image.jpg")

    get root_path

    assert_response :success
    assert_select "img[src='https://example.com/image.jpg'][referrerpolicy='no-referrer']"
  end

  test "only embeds videos on the entry detail page" do
    entry = Entry.create!(title: "Video", url: "https://youtube.com/watch?v=dQw4w9WgXcQ")

    get root_path
    assert_response :success
    assert_select "a iframe", count: 0
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
    assert_select ".entry-detail__media a", count: 0
    assert_select ".entry-detail__url[href^='javascript:']", count: 0
    assert_not_includes response.body, "href=\"javascript:"
  end

  test "links and serves individually versioned stylesheets" do
    get root_path

    assert_response :success
    assert_select "link[rel='stylesheet']", 21
    assert_select "link[href^='/assets/base-'][href$='.css']"
    assert_select "link[href*='application.css']", count: 0
    assert_select "link[href*='?v=']", count: 0
    assert_select "link[data-turbo-track]", count: 0

    base_stylesheet = css_select("link[href^='/assets/base-']").first["href"]
    variables_stylesheet = css_select("link[href^='/assets/variables-']").first["href"]

    get base_stylesheet

    assert_response :success
    assert_includes response.media_type, "text/css"
    assert_includes response.body, "@font-face"

    get variables_stylesheet

    assert_response :success
    assert_includes response.body, "--border-default: 1px solid var(--color-border)"
    assert_not_includes response.body, "--border-default: var(--border-default)"
  end

  test "renders entry notes as sanitized Markdown" do
    entry = Entry.create!(
      title: "Notes",
      url: "https://example.com/notes",
      notes: "# Context\n\nA **useful** note. <script>alert('no')</script>"
    )

    get entry_path(entry)

    assert_response :success
    assert_select ".notes h2", text: "Context"
    assert_select ".notes strong", text: "useful"
    assert_select ".notes script", count: 0
    assert_select "a.entry-detail__url[href='https://example.com/notes'][target='_blank'][rel='noopener']"
  end
end
