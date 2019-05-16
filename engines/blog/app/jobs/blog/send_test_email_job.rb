module Blog
  class SendTestEmailJob < ApplicationJob
    queue_as :default

    def perform(email)
      BlogMailer.with(email: email).new_test_email.deliver_now
    end
  end
end
