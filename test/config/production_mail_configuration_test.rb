require "test_helper"

class ProductionMailConfigurationTest < ActiveSupport::TestCase
  CONFIG = Rails.root.join("config/environments/production.rb").read

  test "builds mail links against the canonical host over HTTPS" do
    assert_includes CONFIG, 'config.action_mailer.default_url_options = { host: "c0mn.com", protocol: "https" }'
  end

  test "uses a real sender on the application domain" do
    assert_equal "no-reply@c0mn.com", ApplicationMailer.default_params[:from]
  end

  test "configures SMTP delivery only when a relay is provided" do
    assert_includes CONFIG, 'if ENV["SMTP_ADDRESS"].present?'
    assert_includes CONFIG, "config.action_mailer.smtp_settings = {"
    assert_includes CONFIG, "config.action_mailer.raise_delivery_errors = true"
  end
end
