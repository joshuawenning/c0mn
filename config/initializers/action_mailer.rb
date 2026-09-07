# Deliveries are enqueued by reference to model instances. If that record is
# deleted before the job runs, the email can no longer be built, so the queued
# delivery is discarded instead of retried into failure.
ActionMailer::MailDeliveryJob.discard_on ActiveJob::DeserializationError
