require "io/console"

namespace :owner do
  desc "Create a platform administrator from OWNER_EMAIL and OWNER_USERNAME"
  task bootstrap: :environment do
    required_variables = %w[OWNER_EMAIL OWNER_USERNAME]
    missing_variables = required_variables.select { |name| ENV[name].blank? }
    abort "Missing #{missing_variables.join(', ')}" if missing_variables.any?

    password = ENV["OWNER_PASSWORD"]
    if password.blank?
      abort "Set OWNER_PASSWORD when input is not interactive." unless $stdin.tty?

      print "Administrator password: "
      password = $stdin.noecho(&:gets).to_s.chomp
      puts
    end

    administrator = User.create!(
      email_address: ENV.fetch("OWNER_EMAIL"),
      username: ENV.fetch("OWNER_USERNAME"),
      password: password,
      password_confirmation: password,
      platform_admin: true
    )

    puts "Created platform administrator #{administrator.email_address} (#{administrator.username})."
  end
end
