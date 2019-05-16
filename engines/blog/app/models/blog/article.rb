module Blog
  class Article < ApplicationRecord
    has_one :article_email_history, foreign_key: :blog_article_id
  end
end
