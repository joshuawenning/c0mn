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
end
