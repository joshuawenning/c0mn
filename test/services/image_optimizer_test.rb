require "test_helper"

class ImageOptimizerTest < ActiveSupport::TestCase
  test "produces capped still WebP images without upscaling" do
    Tempfile.create([ "source", ".png" ]) do |file|
      Vips::Image.black(1800, 900).pngsave(file.path)
      results = ImageOptimizer.call(file.path)
      ImageOptimizer::SIZES.each do |name, (dimension, cap)|
        result = results.fetch(name)
        assert_operator result[:bytes].bytesize, :<=, cap
        image = Vips::Image.new_from_buffer(result[:bytes], "")
        assert_operator image.width, :<=, dimension
        assert_equal 2, image.width / image.height
      end
    end
    Tempfile.create([ "small", ".png" ]) do |file|
      Vips::Image.black(10, 5).pngsave(file.path)
      assert_equal 10, ImageOptimizer.call(file.path)[:master][:width]
    end
  end

  test "rejects non-image contents and excessive pixel dimensions" do
    Tempfile.create do |file|
      file.write("not an image")
      file.flush
      assert_raises(ImageOptimizer::Error) { ImageOptimizer.call(file.path) }
      Vips::Image.black(7000, 7000).pngsave(file.path)
      assert_raises(ImageOptimizer::Error) { ImageOptimizer.call(file.path) }
    end
  end

  test "flattens animated images to the first frame" do
    Tempfile.create([ "animation", ".webp" ]) do |file|
      frames = Vips::Image.arrayjoin([ Vips::Image.black(40, 20), Vips::Image.black(40, 20) + 255 ], across: 1)
      frames.webpsave(file.path, page_height: 20)
      assert_equal 2, Vips::Image.new_from_file(file.path, n: -1).get("n-pages")
      ImageOptimizer.call(file.path).each_value do |result|
        image = Vips::Image.new_from_buffer(result[:bytes], "", n: -1)
        assert_equal 20, image.height
        assert_operator image.avg, :<, 2
      end
    end
  end

  test "accepts GIF contents through the libvips NSGIF loader" do
    Tempfile.create([ "gif", ".gif" ]) do |file|
      Vips::Image.black(40, 20).gifsave(file.path)
      assert_equal 40, ImageOptimizer.call(file.path)[:master][:width]
    end
  end

  test "keeps high entropy images below every byte cap" do
    Tempfile.create([ "noise", ".png" ]) do |file|
      bands = 3.times.map { Vips::Image.gaussnoise(1800, 1800, sigma: 100).cast(:uchar) }
      bands.first.bandjoin(bands.drop(1)).pngsave(file.path)
      ImageOptimizer.call(file.path).each do |kind, result|
        assert_operator result[:bytes].bytesize, :<=, ImageOptimizer::SIZES.fetch(kind).last
      end
    end
  end
end
