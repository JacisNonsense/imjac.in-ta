class CreateBlogArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :blog_articles do |t|
      t.string :file
      t.string :title
      t.string :blog
      t.string :author
      t.string :categories
      t.string :excerpt
      t.string :header_img
      t.datetime :publish_time

      t.timestamps
    end
    add_index :blog_articles, :file, unique: true
  end
end
