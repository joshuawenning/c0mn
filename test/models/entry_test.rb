require "test_helper"

class EntryTest < ActiveSupport::TestCase
  test "stores entry copy only as notes" do
    assert_includes Entry.column_names, "notes"
    assert_not_includes Entry.column_names, "description"
  end

  test "orders entries consistently when collection and creation times match" do
    timestamp = Time.current.change(usec: 0)
    entries = 3.times.map do |index|
      Entry.create!(title: "Tie #{index}", url: "https://example.com/tie-#{index}", collected_at: timestamp, created_at: timestamp)
    end

    assert_equal entries.reverse.map(&:id), Entry.recent.ids
  end

  test "requires a regular http url" do
    entry = Entry.new(title: "Local file", url: "/notes/image.jpg")

    assert_not entry.valid?
    assert_includes entry.errors[:url], "must be a regular http or https link"
  end

  test "rejects executable URL schemes" do
    entry = Entry.new(title: "Unsafe", url: "javascript:alert('no')")

    assert_not entry.valid?
    assert_includes entry.errors[:url], "must be a regular http or https link"
  end

  test "rejects script resources and urls containing credentials" do
    script = Entry.new(title: "Script", url: "https://example.com/application.js")
    credentialed = Entry.new(title: "Private", url: "https://user:secret@example.com/private")

    assert_not script.valid?
    assert_includes script.errors[:url], "must be a regular http or https link"
    assert_not credentialed.valid?
    assert_includes credentialed.errors[:url], "must be a regular http or https link"
  end

  test "assigns comma separated tags" do
    entry = create_entry!(title: "Garden", url: "https://example.com/garden", tag_list: "Landscape, ecology, landscape")

    assert_equal [ "ecology", "landscape" ], entry.tags.order(:name).pluck(:name)
    assert_equal "ecology, landscape", entry.tag_list
  end

  test "validates once and uses fresh tags on subsequent saves" do
    entry = Entry.new(title: "Garden", url: "https://example.com/garden", tag_list: "landscape")
    validations = 0
    entry.define_singleton_method(:valid?) do |*arguments|
      validations += 1
      super(*arguments)
    end

    assert entry.save_with_tags
    assert_equal 1, validations

    entry.tag_list = "Ecology, ecology"
    assert entry.save_with_tags
    assert_equal "ecology", entry.tag_list
    assert_equal [ "ecology" ], entry.reload.tags.pluck(:name)
  end

  test "rolls back the entry and new tags when a later tag is invalid" do
    Tag.create!(name: "c++")
    entry = Entry.new(title: "Languages", url: "https://example.com/languages", tag_list: "new tag, c#")

    assert_no_difference [ "Entry.count", "Tag.count", "Tagging.count" ] do
      assert_not entry.save_with_tags
    end

    assert entry.new_record?
    assert_equal "new tag, c#", entry.tag_list
    assert entry.errors[:tag_list].any?
  end

  test "rolls back an edited entry and retains submitted tags on failure" do
    Tag.create!(name: "c++")
    entry = create_entry!(title: "Original", url: "https://example.com/original", tag_list: "shared")
    entry.assign_attributes(title: "Edited", tag_list: "new tag, c#")

    assert_no_difference [ "Tag.count", "Tagging.count" ] do
      assert_not entry.save_with_tags
    end
    assert_equal "new tag, c#", entry.tag_list
    assert_equal "Original", Entry.find(entry.id).title
    assert_equal [ "shared" ], Entry.find(entry.id).tags.pluck(:name)
  end

  test "resolves color collisions between new tags in one submission" do
    entry = create_entry!(title: "Colors", url: "https://example.com/colors", tag_list: "collision-292, collision-3137")

    assert_equal 2, entry.tags.count
    assert_equal 2, entry.tags.pluck(:color).uniq.size
    assert_equal "#81604e", Tag.find_by!(name: "collision-292").color
  end

  test "assigns each new tag a distinct color" do
    first = Tag.create!(name: "architecture")
    second = Tag.create!(name: "ecology")

    assert_match(/\A#[0-9a-f]{6}\z/i, first.color)
    assert_not_equal first.color, second.color
  end

  test "infers image media kind from url" do
    entry = Entry.create!(title: "Image", url: "https://example.com/photo.webp")

    assert_equal "image", entry.media_kind
    assert_equal "example.com", entry.source_name
  end

  test "uses accompanying image url for non-image entries" do
    entry = Entry.create!(
      title: "Article",
      url: "https://example.com/post",
      image_url: "https://cdn.example.com/post.jpg"
    )

    assert_equal "https://cdn.example.com/post.jpg", entry.embeddable_image_url
  end

  test "requires accompanying image url to be absolute when present" do
    entry = Entry.new(title: "Article", url: "https://example.com/post", image_url: "image.jpg")

    assert_not entry.valid?
    assert_includes entry.errors[:image_url], "must be an HTTPS URL ending in avif, gif, jpg, jpeg, png, or webp"
  end

  test "requires image urls to use https raster image extensions" do
    insecure = Entry.new(title: "Image", url: "http://example.com/photo.jpg")
    svg = Entry.new(title: "Image", url: "https://example.com/photo.svg", media_kind: "image")
    script = Entry.new(
      title: "Article",
      url: "https://example.com/post",
      image_url: "https://example.com/preview.js"
    )

    assert_not insecure.valid?
    assert_includes insecure.errors[:url], "must be an HTTPS image ending in avif, gif, jpg, jpeg, png, or webp"
    assert_not svg.valid?
    assert_includes svg.errors[:url], "must be an HTTPS image ending in avif, gif, jpg, jpeg, png, or webp"
    assert_not script.valid?
    assert script.errors[:image_url].any?
  end

  test "recomputes automatic metadata when the url changes" do
    entry = Entry.create!(title: "Image", url: "https://images.example.com/photo.jpg")

    entry.update!(url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")

    assert_equal "youtube.com", entry.source_name
    assert_equal "video", entry.media_kind
  end

  test "preserves explicit metadata when the url changes" do
    entry = Entry.create!(
      title: "Reference",
      url: "https://example.com/reference",
      source_name: "Personal archive",
      media_kind: "article"
    )

    entry.update!(url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")

    assert_equal "Personal archive", entry.source_name
    assert_equal "article", entry.media_kind
  end

  test "clearing metadata overrides restores inference" do
    entry = Entry.create!(title: "Reference", url: "https://example.com/image.jpg", source_name: "Custom", media_kind: "article")

    entry.update!(source_name: "", media_kind: "")

    assert_equal "example.com", entry.source_name
    assert_equal "image", entry.media_kind
    assert_not entry.source_name_overridden?
    assert_not entry.media_kind_overridden?
  end

  test "preserves tags when another attribute is invalid" do
    entry = create_entry!(title: "Garden", url: "https://example.com/garden", tag_list: "landscape")

    entry.assign_attributes(title: "", tag_list: "ecology")
    assert_not entry.save_with_tags

    assert_equal [ "landscape" ], entry.reload.tags.pluck(:name)
  end

  test "retains unused tags after replacement and entry deletion" do
    entry = create_entry!(title: "Garden", url: "https://example.com/garden", tag_list: "landscape")

    entry.tag_list = "ecology"
    assert entry.save_with_tags

    assert Tag.exists?(name: "landscape")
    assert Tag.exists?(name: "ecology")

    entry.destroy!

    assert Tag.exists?(name: "ecology")
  end

  test "retains a shared tag when one entry changes its tags" do
    first = create_entry!(title: "First", url: "https://example.com/first", tag_list: "shared")
    second = create_entry!(title: "Second", url: "https://example.com/second", tag_list: "shared")

    first.tag_list = "replacement"
    assert first.save_with_tags

    assert_equal [ "shared" ], second.reload.tags.pluck(:name)
  end

  test "combines tag filters with searches matching another tag" do
    entry = create_entry!(title: "House", url: "https://example.com/house", tag_list: "architecture, music")

    results = Entry.tagged_with("architecture").search("music")

    assert_equal [ entry ], results.to_a
  end

  test "searches for literal wildcard characters" do
    percent = Entry.create!(title: "A 100% guide", url: "https://example.com/percent")
    Entry.create!(title: "A plain guide", url: "https://example.com/plain")

    assert_equal [ percent ], Entry.search("%").to_a
  end

  test "rejects tag names whose slug collides" do
    Tag.create!(name: "c++")
    entry = Entry.new(title: "Languages", url: "https://example.com/languages", tag_list: "c#")

    assert_no_difference "Entry.count" do
      assert_not entry.save_with_tags
    end
    assert entry.errors[:tag_list].any?
  end

  test "reports duplicate urls on the url field" do
    create_entry!(title: "Original", url: "https://example.com/duplicate")
    duplicate = Entry.new(title: "Duplicate", url: "https://example.com/duplicate", tag_list: "example")

    assert_not duplicate.save_with_tags
    assert_includes duplicate.errors[:url], "has already been taken"
    assert_empty duplicate.errors[:tag_list]
  end

  test "only embeds exact youtube domains" do
    valid = Entry.create!(title: "Video", url: "https://youtube.com/shorts/dQw4w9WgXcQ")
    lookalike = Entry.create!(title: "Not video", url: "https://youtube.com.example.org/watch?v=dQw4w9WgXcQ")

    assert_equal "https://www.youtube.com/embed/dQw4w9WgXcQ", valid.youtube_embed_url
    assert_equal "link", lookalike.media_kind
    assert_nil lookalike.youtube_embed_url
  end
end
