class AddUsernameToDevUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :dev_users, :username, :string
    add_index :dev_users, :username, unique: true
  end
end
