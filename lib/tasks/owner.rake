require "io/console"

namespace :owner do
  desc "Create the initial platform owner from OWNER_EMAIL and OWNER_USERNAME"
  task bootstrap: :environment do
    required_variables = %w[OWNER_EMAIL OWNER_USERNAME]
    missing_variables = required_variables.select { |name| ENV[name].blank? }
    abort "Missing #{missing_variables.join(', ')}" if missing_variables.any?
    abort "A platform owner already exists." if User.exists?(platform_admin: true)

    password = ENV["OWNER_PASSWORD"]
    if password.blank?
      abort "Set OWNER_PASSWORD when input is not interactive." unless $stdin.tty?

      print "Owner password: "
      password = $stdin.noecho(&:gets).to_s.chomp
      puts
    end

    owner = User.create!(
      email_address: ENV.fetch("OWNER_EMAIL"),
      username: ENV.fetch("OWNER_USERNAME"),
      password: password,
      password_confirmation: password,
      platform_admin: true
    )

    puts "Created platform owner #{owner.email_address} (#{owner.username})."
  end
end
