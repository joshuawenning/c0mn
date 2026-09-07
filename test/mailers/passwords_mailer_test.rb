require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "sends the reset message to the account email from the configured sender" do
    user = users(:owner)
    email = PasswordsMailer.reset(user)

    assert_equal [ user.email_address ], email.to
    assert_equal [ ApplicationMailer.default_params[:from] ], email.from
    assert_equal "Reset your password", email.subject
  end

  test "links to the reset page on the configured host and protocol" do
    options = Rails.application.config.action_mailer.default_url_options
    base = "#{options.fetch(:protocol, "http")}://#{options[:host]}"
    reset_pattern = %r{#{Regexp.escape(base)}/passwords/[^"'<]+/edit}

    email = PasswordsMailer.reset(users(:owner))

    assert_match reset_pattern, email.html_part.decoded
    assert_match reset_pattern, email.text_part.decoded
  end

  test "delivers the reset message" do
    user = users(:owner)

    assert_emails 1 do
      PasswordsMailer.reset(user).deliver_now
    end
  end
end
