module Blog
  class ArticleEmailHistory < ApplicationRecord
    belongs_to :article, foreign_key: :blog_article_id
  end
end
