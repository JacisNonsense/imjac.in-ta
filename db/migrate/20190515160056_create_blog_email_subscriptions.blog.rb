# This migration comes from blog (originally 20190515152419)
class CreateBlogEmailSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :blog_email_subscriptions do |t|
      t.string :email
      t.string :unsubscribe_token
      t.boolean :subscribed

      t.timestamps
    end
    add_index :blog_email_subscriptions, :email, unique: true
    add_index :blog_email_subscriptions, :unsubscribe_token, unique: true
  end
end
