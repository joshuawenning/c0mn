require "test_helper"

class Admin::EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:owner)
    @entry = create_entry!(
      title: "Garden",
      url: "https://example.com/garden",
      image_url: "https://cdn.example.com/garden.jpg",
      tag_list: "landscape"
    )
  end

  test "renders admin index for an administrator" do
    link_entry = Entry.create!(title: "Reading list", url: "https://example.org/reading")

    get admin_entries_path

    assert_response :success
    assert_rendered_entries @entry, link_entry
    assert_select "form[action='#{logout_path}']"
  end

  test "paginates and clamps the admin index" do
    Admin::EntriesController::PAGE_SIZE.times do |index|
      Entry.create!(title: "Paginated #{index}", url: "https://example.org/paginated-#{index}")
    end

    get admin_entries_path(page: 10_000)

    assert_response :success
    assert_rendered_entries @entry
    assert_select "a[href='#{admin_entries_path(page: 1)}']"
    assert_select "a[href='#{admin_entries_path(page: 3)}']", count: 0
  end

  test "treats malformed page numbers as the first page" do
    [ [ "2" ], { value: "2" }, "abc", "0", "-2" ].each do |page|
      get admin_entries_path, params: { page: page }

      assert_response :success
      assert_rendered_entries @entry
    end
  end

  test "rejects malformed entry parameters without writing records" do
    [ "not an entry", [ { title: "Unexpected" } ] ].each do |entry|
      assert_no_difference "Entry.count" do
        post admin_entries_path, params: { entry: entry }
      end

      assert_response :bad_request
    end
  end

  test "renders an entry's detail and edit destinations" do
    get admin_entry_path(@entry)

    assert_response :success
    assert_select "a[href='#{@entry.url}'][target='_blank'][rel='noopener']"
    assert_select "a[href='#{edit_admin_entry_path(@entry)}']"

    get edit_admin_entry_path(@entry)

    assert_response :success
    assert_select "form[action='#{admin_entry_path(@entry)}']"
    assert_select "[name='entry[title]'][value='#{@entry.title}']"
  end

  test "does not show inferred fields for a new entry" do
    get new_admin_entry_path

    assert_response :success
    assert_select "form[action='#{admin_entries_path}']"
    assert_select "input[name='entry[source_name]']", count: 0
    assert_select "[name='entry[notes]']"
  end

  test "creates an entry" do
    assert_difference "Entry.count" do
      post admin_entries_path, params: {
        entry: {
          title: "Video",
          url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          image_url: "https://example.com/video.jpg",
          media_kind: "link",
          tag_list: "music, video"
        }
      }
    end

    assert_redirected_to admin_entry_path(Entry.last)
    assert_equal "link", Entry.last.media_kind
    assert_equal "https://example.com/video.jpg", Entry.last.image_url
    assert_equal "youtube.com", Entry.last.source_name
    assert_not Entry.last.source_name_overridden?
  end

  test "updates an entry" do
    patch admin_entry_path(@entry), params: { entry: { title: "Updated Garden", tag_list: "ecology" } }

    assert_redirected_to admin_entry_path(@entry)
    assert_response :see_other
    assert_equal "Updated Garden", @entry.reload.title
    assert_equal [ "ecology" ], @entry.tags.pluck(:name)
  end

  test "does not change tags when an update is invalid" do
    patch admin_entry_path(@entry), params: { entry: { title: "", tag_list: "ecology" } }

    assert_response :unprocessable_entity
    assert_equal [ "landscape" ], @entry.reload.tags.pluck(:name)
    assert_invalid_field "entry[title]"
  end

  test "destroys an entry and retains its tags" do
    assert_difference "Entry.count", -1 do
      assert_no_difference "Tag.count" do
        delete admin_entry_path(@entry)
      end
    end

    assert_redirected_to admin_entries_path
  end

  test "redirects anonymous visitors to login" do
    sign_out
    get admin_entries_path

    assert_redirected_to new_session_path
  end

  test "does not allow anonymous mutations" do
    sign_out

    assert_no_difference "Entry.count" do
      post admin_entries_path, params: { entry: { title: "Unauthorized", url: "https://example.org/unauthorized" } }
    end

    assert_redirected_to new_session_path
    assert_response :see_other
  end

  test "forbids authenticated non-admin users" do
    sign_out
    sign_in_as users(:member)

    get admin_entries_path

    assert_response :forbidden
  end

  test "does not allow non-admin mutations" do
    sign_out
    sign_in_as users(:member)

    assert_no_changes -> { @entry.reload.title } do
      patch admin_entry_path(@entry), params: { entry: { title: "Unauthorized" } }
    end

    assert_response :forbidden
  end

  private
    def assert_rendered_entries(*entries)
      paths = css_select("a[href]").map { |link| link["href"] }.grep(%r{\A/admin/entries/\d+\z}).uniq.sort
      assert_equal entries.map { |entry| admin_entry_path(entry) }.sort, paths
    end
end
