require "test_helper"

class EntryUrlTest < ActiveSupport::TestCase
  test "accepts regular http and https links" do
    assert EntryUrl.new("http://example.com/articles/one").valid?
    assert EntryUrl.new("https://example.com/articles/one?q=rails#notes").valid?
  end

  test "rejects non-web schemes and relative links" do
    %w[javascript:alert(1) data:text/plain,hello file:///tmp/note /local/path].each do |url|
      assert_not EntryUrl.new(url).valid?, url
    end
  end

  test "rejects links containing credentials" do
    assert_not EntryUrl.new("https://user:secret@example.com/private").valid?
  end

  test "rejects known active content extensions including encoded paths" do
    %w[
      https://example.com/app.js
      https://example.com/app.MJS?download=1
      https://example.com/module.cjs
      https://example.com/module.wasm
      https://example.com/app%2Ejs
    ].each do |url|
      assert_not EntryUrl.new(url).valid?, url
    end
  end

  test "accepts only https raster image urls as images" do
    assert EntryUrl.new("https://cdn.example.com/photo.JPEG?size=large#preview").image?
    assert_not EntryUrl.new("http://cdn.example.com/photo.jpg").image?
    assert_not EntryUrl.new("https://cdn.example.com/photo.svg").image?
    assert_not EntryUrl.new("https://cdn.example.com/image?id=1").image?
  end

  test "builds embeds only for safe youtube urls" do
    assert_equal "https://www.youtube.com/embed/dQw4w9WgXcQ",
      EntryUrl.new("https://youtube.com/watch?v=dQw4w9WgXcQ").youtube_embed_url
    assert_nil EntryUrl.new("https://user:secret@youtube.com/watch?v=dQw4w9WgXcQ").youtube_embed_url
    assert_nil EntryUrl.new("https://youtube.com.example.org/watch?v=dQw4w9WgXcQ").youtube_embed_url
  end
end
