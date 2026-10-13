require "test_helper"
require_relative "../test_helpers/method_override_helper"

class ImageDownloadTest < ActiveSupport::TestCase
  include MethodOverrideHelper
  test "rejects local and reserved addresses including mapped IPv4" do
    %w[127.0.0.1 10.1.2.3 169.254.169.254 192.168.1.1 ::1 fc00::1 fe80::1 ::ffff:127.0.0.1 2001:db8::1].each do |address|
      assert_not ImageDownload.public_address?(address), address
    end
    assert ImageDownload.public_address?("1.1.1.1")
    assert ImageDownload.public_address?("2606:4700:4700::1111")
  end

  test "rejects insecure URLs before downloading" do
    %w[http://example.com/a.jpg https://user:password@example.com/a.jpg https://example.com:8443/a.jpg].each do |url|
      assert_raises(ImageDownload::Error) { ImageDownload.open(url) { flunk } }
    end
  end

  test "pins the public address and bounds streamed downloads" do
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.define_singleton_method(:read_body) { |&block| block.call("image bytes") }
    http = fake_http(response)
    with_method(Resolv, :getaddresses, ->(*) { [ "1.1.1.1" ] }) do
      with_method(Net::HTTP, :new, ->(*) { http }) do
        ImageDownload.open("https://example.com/a.png") { |file| assert_equal "image bytes", file.read }
        assert_equal "1.1.1.1", http.ipaddr
        response["content-length"] = (ImageDownload::MAX_BYTES + 1).to_s
        assert_raises(ImageDownload::Error) { ImageDownload.open("https://example.com/a.png") { flunk } }
        response.delete("content-length")
        response.define_singleton_method(:read_body) { |&block| block.call("x" * (ImageDownload::MAX_BYTES + 1)) }
        assert_raises(ImageDownload::Error) { ImageDownload.open("https://example.com/a.png") { flunk } }
      end
    end
  end

  test "validates redirects before connecting to private destinations" do
    response = Net::HTTPFound.new("1.1", "302", "Found")
    response["location"] = "https://127.0.0.1/internal.png"
    http = fake_http(response)
    resolver = ->(host) { host == "example.com" ? [ "1.1.1.1" ] : [ "127.0.0.1" ] }
    with_method(Resolv, :getaddresses, resolver) do
      with_method(Net::HTTP, :new, ->(*) { http }) do
        assert_raises(ImageDownload::Error) { ImageDownload.open("https://example.com/a.png") { flunk } }
      end
    end
  end

  private

  def fake_http(response)
    Class.new do
      attr_accessor :ipaddr, :use_ssl, :open_timeout, :read_timeout, :max_retries
      define_method(:start) { |&block| block.call }
      define_method(:request) { |_request, &block| block.call(response) }
    end.new
  end
end
