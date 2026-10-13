require "vips"

class ImageOptimizer
  class Error < StandardError; end
  MAX_PIXELS = 40_000_000
  SIZES = { master: [ 1600, 500_000 ], card: [ 640, 100_000 ], thumbnail: [ 224, 25_000 ] }.freeze
  LOADERS = %w[foreignloadjpeg foreignloadpng foreignloadwebp foreignloadgif foreignloadheif].freeze

  def self.call(path)
    loader = Vips.vips_foreign_find_load(path)
    raise Error, "Unsupported image contents" unless loader && LOADERS.any? { |name| loader.downcase.include?(name) }
    image = Vips::Image.new_from_file(path)
    raise Error, "Image exceeds 40 million pixels" if image.width * image.height > MAX_PIXELS
    # The default loader reads only the first frame/page.
    image = image.autorot.copy_memory
    SIZES.transform_values do |dimension, cap|
      encode(image, dimension, cap)
    end
  rescue Vips::Error => error
    raise Error, "Unable to process image: #{error.message.truncate(200)}"
  end

  def self.encode(image, dimension, cap)
    loop do
      scale = [ dimension.to_f / [ image.width, image.height ].max, 1 ].min
      resized = scale < 1 ? image.resize(scale) : image
      [ 80, 70, 60, 50, 40 ].each do |quality|
        bytes = resized.webpsave_buffer(Q: quality, strip: true)
        return { bytes: bytes, width: resized.width, height: resized.height } if bytes.bytesize <= cap
      end
      dimension = (dimension * 0.8).floor
      raise Error, "Unable to meet image size limit" if dimension < 32
    end
  end
end
