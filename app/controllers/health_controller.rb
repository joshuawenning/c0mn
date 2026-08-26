class HealthController < ActionController::Base
  rescue_from(Exception) { render_down }

  before_action :set_response_headers

  def show
    @architecture = architecture
    @checked_at = Time.current
    @hosting = Rails.env.production? ? "Hetzner Cloud" : "Local development"
    @release = ENV["KAMAL_VERSION"].to_s.first(12).presence || Rails.env

    respond_to do |format|
      format.html
      format.json { render json: { status: "up", timestamp: @checked_at.iso8601 } }
    end
  end

  private

  def architecture
    case RbConfig::CONFIG["host_cpu"].downcase
    when /amd64|x86_64/
      "AMD64"
    when /aarch64|arm64/
      "ARM64"
    else
      RbConfig::CONFIG["host_cpu"]
    end
  end

  def render_down
    respond_to do |format|
      format.html { render plain: "down", status: :internal_server_error }
      format.json { render json: { status: "down", timestamp: Time.current.iso8601 }, status: :internal_server_error }
    end
  rescue StandardError
    head :internal_server_error
  end

  def set_response_headers
    response.set_header("Cache-Control", "no-store")
    response.set_header("X-Robots-Tag", "noindex, nofollow")
  end
end
