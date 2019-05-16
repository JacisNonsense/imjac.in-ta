require 'date' 

module Blog
  class SendMailingListJob < ApplicationJob
    queue_as :default

    # Only consider posts within the last X days
    DATE_THRESH = 300
    NUMBER_OF_POSTS_MAX = 3

    def perform
      today = Date.today
      articles = Article.order(publish_time: :desc)
                  .limit(NUMBER_OF_POSTS_MAX)
                  .select { |art| art.article_email_history.nil? && (today - art.publish_time.to_date).to_i < DATE_THRESH }
      
      unless articles.empty?
        subscriptions = EmailSubscription.where(subscribed: true)

        # Mark articles as sent
        articles.each do |article|
          eh = ArticleEmailHistory.find_or_initialize_by(article: article)
          eh.recipient_count = subscriptions.count
          eh.save
        end

        # Queue email jobs
        subscriptions.each do |subscription|
          SendArticlesToEmailJob.perform_later subscription, articles
        end
      end
    end
  end
end
