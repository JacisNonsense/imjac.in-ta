module Blog
  class SendArticlesToEmailJob < ApplicationJob
    queue_as :default

    def perform(subscription, articles)
      unless articles.empty?
        BlogMailer.with(subscription: subscription, articles: articles).new_article_email.deliver_now
      end
    end
  end
end
