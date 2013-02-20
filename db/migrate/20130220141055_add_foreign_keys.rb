class AddForeignKeys < ActiveRecord::Migration
  def up
    add_foreign_key :friendships, :users, column: 'user_id' 
    add_foreign_key :friendships, :users, column: 'friend_id'
    add_foreign_key :user_page_relationships, :users, column: 'user_id'
    add_foreign_key :user_page_relationships, :pages, column: 'page_id'

  end

  def down
  end
end
