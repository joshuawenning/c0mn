require "test_helper"

class ApplicationJobTest < ActiveJob::TestCase
  test "discards queued mail when its user is deleted before delivery" do
    user = users(:owner)

    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      PasswordsMailer.reset(user).deliver_later
    end

    user.destroy!

    assert_nothing_raised { perform_enqueued_jobs }
    assert_equal 0, ActionMailer::Base.deliveries.size
  end
end
