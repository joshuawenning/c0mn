require "application_system_test_case"

class CollectionsTest < ApplicationSystemTestCase
  test "renders the collection and opens an entry detail page" do
    entry = create_entry!(title: "A house in Mallorca", url: "https://example.com/house", tag_list: "architecture")

    visit root_path

    find("a[href='#{entry_path(entry)}']", match: :first).click

    assert_current_path entry_path(entry)
    assert_text(/#{Regexp.escape(entry.title)}/i)
    assert_selector "a[href='#{root_path(tag: 'architecture')}']"
  end

  test "follows a Turbo entry update with the detail page" do
    entry = create_entry!(title: "Original", url: "https://example.com/edited", tag_list: "reference")
    sign_in_through_browser
    visit edit_admin_entry_path(entry)

    fill_in "Title", with: "Updated reference"
    fill_in "Tags", with: "design"
    click_button "Update Entry"

    assert_current_path admin_entry_path(entry)
    assert_text(/Updated reference/i)
    assert_equal "Updated reference", entry.reload.title
    assert_equal [ "design" ], entry.tags.pluck(:name)
  end

  test "an expired session redirects a Turbo update to sign in without saving" do
    entry = Entry.create!(title: "Original", url: "https://example.com/expired")
    sign_in_through_browser
    visit edit_admin_entry_path(entry)
    assert_selector "input[name='entry[title]']"
    users(:owner).sessions.delete_all

    fill_in "Title", with: "Unauthorized edit"
    click_button "Update Entry"

    assert_current_path new_session_path
    assert_selector "form[action='#{session_path}']"
    assert_equal "Original", entry.reload.title
  end

  private
    def sign_in_through_browser
      visit new_session_path
      fill_in "Email", with: users(:owner).email_address
      fill_in "Password", with: "a secure password"
      click_button "Sign in"
      assert_current_path root_path
    end
end
