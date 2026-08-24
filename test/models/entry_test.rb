require "test_helper"

class EntryTest < ActiveSupport::TestCase
  test "stores entry copy only as notes" do
    assert_includes Entry.column_names, "notes"
    assert_not_includes Entry.column_names, "description"
  end

  test "requires an absolute http url" do
    entry = Entry.new(title: "Local file", url: "/notes/image.jpg")

    assert_not entry.valid?
    assert_includes entry.errors[:url], "must be an absolute http or https URL"
  end

  test "rejects executable URL schemes" do
    entry = Entry.new(title: "Unsafe", url: "javascript:alert('no')")

    assert_not entry.valid?
    assert_includes entry.errors[:url], "must be an absolute http or https URL"
  end

  test "assigns comma separated tags" do
    entry = Entry.create!(title: "Garden", url: "https://example.com/garden", tag_list: "Landscape, ecology, landscape")

    assert_equal [ "ecology", "landscape" ], entry.tags.order(:name).pluck(:name)
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
    assert_includes entry.errors[:image_url], "must be an absolute https URL"
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

  test "preserves tags when another attribute is invalid" do
    entry = Entry.create!(title: "Garden", url: "https://example.com/garden", tag_list: "landscape")

    assert_not entry.update(title: "", tag_list: "ecology")

    assert_equal [ "landscape" ], entry.reload.tags.pluck(:name)
  end

  test "deletes tags orphaned by replacement and entry deletion" do
    entry = Entry.create!(title: "Garden", url: "https://example.com/garden", tag_list: "landscape")

    entry.update!(tag_list: "ecology")

    assert_not Tag.exists?(name: "landscape")
    assert Tag.exists?(name: "ecology")

    entry.destroy!

    assert_not Tag.exists?(name: "ecology")
  end

  test "combines tag filters with searches matching another tag" do
    entry = Entry.create!(title: "House", url: "https://example.com/house", tag_list: "architecture, music")

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

    assert_not entry.save
    assert entry.errors[:tag_list].any?
  end

  test "only embeds exact youtube domains" do
    valid = Entry.create!(title: "Video", url: "https://youtube.com/shorts/dQw4w9WgXcQ")
    lookalike = Entry.create!(title: "Not video", url: "https://youtube.com.example.org/watch?v=dQw4w9WgXcQ")

    assert_equal "https://www.youtube.com/embed/dQw4w9WgXcQ", valid.youtube_embed_url
    assert_equal "link", lookalike.media_kind
    assert_nil lookalike.youtube_embed_url
  end
end
