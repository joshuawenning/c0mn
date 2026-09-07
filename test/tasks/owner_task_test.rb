require "test_helper"
require "rake"

Rails.application.load_tasks unless Rake::Task.task_defined?("owner:bootstrap")

class OwnerTaskTest < ActiveSupport::TestCase
  setup do
    @task = Rake::Task["owner:bootstrap"]
    @previous_environment = ENV.values_at("OWNER_EMAIL", "OWNER_USERNAME", "OWNER_PASSWORD")
  end

  teardown do
    %w[OWNER_EMAIL OWNER_USERNAME OWNER_PASSWORD].zip(@previous_environment).each do |name, value|
      value ? ENV[name] = value : ENV.delete(name)
    end
    @task.reenable
  end

  test "creates a platform administrator" do
    User.destroy_all
    ENV.update(
      "OWNER_EMAIL" => "owner@example.com",
      "OWNER_USERNAME" => "josh",
      "OWNER_PASSWORD" => "a generated password"
    )

    assert_difference "User.count", 1 do
      capture_io { @task.invoke }
    end

    administrator = User.find_by!(email_address: "owner@example.com")
    assert administrator.platform_admin?
    assert administrator.authenticate("a generated password")
  end

  test "creates additional platform administrators" do
    ENV.update(
      "OWNER_EMAIL" => "another@example.com",
      "OWNER_USERNAME" => "another",
      "OWNER_PASSWORD" => "a generated password"
    )

    assert_difference "User.where(platform_admin: true).count", 1 do
      capture_io { @task.invoke }
    end

    assert User.find_by!(email_address: "another@example.com").platform_admin?
  end
end
