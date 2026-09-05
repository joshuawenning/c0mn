require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
  test "renders the public collection" do
    Entry.create!(title: "A house in Mallorca", url: "https://example.com/house.jpg", tag_list: "architecture")

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

  test "shows admin navigation only to the signed-in owner" do
    sign_in_as users(:owner)

    get root_path

    assert_response :success
    assert_select "a[href='#{admin_root_path}']", text: "Admin"
  end

  test "filters by tag" do
    Entry.create!(title: "A house", url: "https://example.com/house", tag_list: "architecture")
    Entry.create!(title: "A song", url: "https://example.com/song", tag_list: "music")

    get root_path(tag: "architecture")

    assert_response :success
    assert_includes response.body, "A house"
    assert_not_includes response.body, "A song"
  end

  test "searches within a different tag while filtering" do
    Entry.create!(title: "A house", url: "https://example.com/house", tag_list: "architecture, music")

    get root_path(tag: "architecture", q: "music")

    assert_response :success
    assert_includes response.body, "A house"
  end

  test "includes a content security policy" do
    get root_path

    assert_includes response.headers["Content-Security-Policy"], "frame-src 'self' https://www.youtube.com"
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
      notes: "## Context\n\nA **useful** note. <script>alert('no')</script>"
    )

    get entry_path(entry)

    assert_response :success
    assert_select ".notes h2", text: "Context"
    assert_select ".notes strong", text: "useful"
    assert_select ".notes script", count: 0
    assert_select "a.entry-detail__url[href='https://example.com/notes'][target='_blank'][rel='noopener']"
  end
end
