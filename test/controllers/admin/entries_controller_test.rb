require "test_helper"

class Admin::EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:owner)
    @entry = Entry.create!(
      title: "Garden",
      url: "https://example.com/garden",
      image_url: "https://cdn.example.com/garden.jpg",
      tag_list: "landscape"
    )
  end

  test "renders admin index for the owner" do
    link_entry = Entry.create!(title: "Reading list", url: "https://example.org/reading")

    get admin_entries_path

    assert_response :success
    assert_select "h1", text: "Collection entries"
    assert_select "form[action='#{logout_path}'] button", text: "Sign out"
    assert_select ".admin-row .admin-entry-preview img[src='https://cdn.example.com/garden.jpg']"
    assert_select "#entry_#{link_entry.id}" do
      assert_select ".admin-preview--placeholder .admin-preview__placeholder", text: "link"
      assert_select ".admin-list__content", count: 1
      assert_select ".admin-list__actions", count: 1
    end
  end

  test "shows the image preview on admin detail and edit pages" do
    get admin_entry_path(@entry)

    assert_response :success
    assert_select ".admin-entry-preview img[src='https://cdn.example.com/garden.jpg']"
    assert_select ".admin-facts--without-preview", count: 0
    assert_select ".admin-facts__url a[href='https://example.com/garden'][target='_blank'][rel='noopener']"
    assert_select ".admin-facts__url a[href='https://cdn.example.com/garden.jpg'][target='_blank'][rel='noopener']"

    get edit_admin_entry_path(@entry)

    assert_response :success
    assert_select ".admin-entry-preview img[src='https://cdn.example.com/garden.jpg']"
  end

  test "does not separate facts from an absent link preview" do
    link_entry = Entry.create!(title: "Reading list", url: "https://example.org/reading")

    get admin_entry_path(link_entry)

    assert_response :success
    assert_select ".admin-entry-preview", count: 0
    assert_select "dl.admin-facts--without-preview"
  end

  test "does not show inferred fields for a new entry" do
    get new_admin_entry_path

    assert_response :success
    assert_select "a[href='#{admin_root_path}']", text: "All entries"
    assert_select "a[href='#{new_admin_entry_path}']", text: "New entry", count: 0
    assert_select "input[name='entry[source_name]']", count: 0
    assert_select "[data-controller='markdown-editor']"
    assert_select "textarea[data-markdown-editor-target='input'][name='entry[notes]']"
    assert_select "[role='toolbar'] button", count: 5
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
    assert_equal "Updated Garden", @entry.reload.title
    assert_equal [ "ecology" ], @entry.tags.pluck(:name)
  end

  test "does not change tags when an update is invalid" do
    patch admin_entry_path(@entry), params: { entry: { title: "", tag_list: "ecology" } }

    assert_response :unprocessable_entity
    assert_equal [ "landscape" ], @entry.reload.tags.pluck(:name)
  end

  test "destroys an entry and its orphaned tags" do
    assert_difference [ "Entry.count", "Tag.count" ], -1 do
      delete admin_entry_path(@entry)
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
end
