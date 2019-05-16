# This migration comes from blog (originally 20190515153109)
class CreateBlogArticleEmailHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :blog_article_email_histories do |t|
      t.references :blog_article, index: true, foreign_key: true
      t.integer :recipient_count

      t.timestamps
    end
  end
end
