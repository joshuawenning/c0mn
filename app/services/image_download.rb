require "net/http"
require "ipaddr"
require "resolv"
require "tempfile"

class ImageDownload
  class Error < StandardError; end
  class TransientError < Error; end
  MAX_BYTES = 20.megabytes
  BLOCKED_NETWORKS = %w[0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.0.0.0/24 192.0.2.0/24 192.168.0.0/16 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4].map { |network| IPAddr.new(network) }.freeze

  def self.public_address?(address)
    ip = IPAddr.new(address)
    ip = ip.native if ip.ipv4_mapped?
    ip.ipv4? ? BLOCKED_NETWORKS.none? { |network| network.include?(ip) } : IPAddr.new("2000::/3").include?(ip) && !IPAddr.new("2001::/23").include?(ip) && !IPAddr.new("2002::/16").include?(ip) && !IPAddr.new("2001:db8::/32").include?(ip)
  rescue IPAddr::InvalidAddressError
    false
  end

  def self.open(url)
    Tempfile.create([ "image-import", ".bin" ]) do |file|
      file.binmode
      Timeout.timeout(30) { download(url, file) }
      file.rewind
      yield file
    end
  end

  def self.download(url, file, redirects = 0)
    uri = URI.parse(url)
    raise Error, "Only HTTPS images are supported" unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil? && uri.port == 443
    addresses = Resolv.getaddresses(uri.host)
    raise Error, "Image host is not public" if addresses.empty? || addresses.any? { |address| !public_address?(address) }

    # Pin the validated address while retaining the hostname for TLS verification.
    http = Net::HTTP.new(uri.host, uri.port, nil)
    http.ipaddr = addresses.first
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 10
    http.max_retries = 0
    redirect = catch(:image_redirect) do
      http.start do
        http.request(Net::HTTP::Get.new(uri.request_uri, "Accept" => "image/*", "Accept-Encoding" => "identity")) do |response|
          if response.is_a?(Net::HTTPRedirection)
            raise Error, "Too many image redirects" if redirects >= 3 || response["location"].blank?
            throw :image_redirect, URI.join(uri.to_s, response["location"]).to_s
          else
            raise TransientError, "Image host returned HTTP #{response.code}" if response.code.to_i >= 500 || response.code == "429"
            raise Error, "Image host returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
            raise Error, "Image download exceeds 20 MB" if response["content-length"].to_i > MAX_BYTES
            response.read_body do |chunk|
              raise Error, "Image download exceeds 20 MB" if file.size + chunk.bytesize > MAX_BYTES
              file.write(chunk)
            end
          end
        end
      end
      nil
    end
    download(redirect, file, redirects + 1) if redirect
  rescue URI::InvalidURIError
    raise Error, "Invalid image URL"
  end
end
