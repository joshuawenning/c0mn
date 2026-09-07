require "application_system_test_case"

class CollectionsTest < ApplicationSystemTestCase
  test "renders the collection and opens an entry detail page" do
    create_entry!(title: "A house in Mallorca", url: "https://example.com/house", tag_list: "architecture")

    visit root_path

    assert_selector ".entry-card", count: 1
    assert_text "A house in Mallorca"

    find(".entry-card__title a").click

    assert_selector ".entry-detail__title", text: "A house in Mallorca"
    assert_selector "nav.entry-detail__tags", text: "architecture"
  end
end
