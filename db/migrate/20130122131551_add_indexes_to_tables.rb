class AddIndexesToTables < ActiveRecord::Migration
  def self.up
    add_index :users, :uid
    add_index :users, :birthday
    add_index :pages, :pid
    add_index :pages, :category
    #add_index :user_page_relationships, :user_id       todo: foreign key
    #add_index :user_page_relationships, :page_id
    add_index :user_page_relationships, :relationship_type
    add_index :user_page_relationships, :fb_created_time
  end

  def self.down
    remove_index :users, :uid
    remove_index :users, :birthday
    remove_index :pages, :pid
    remove_index :pages, :category
    #remove_index :user_page_relationships, :user_id
    #remove_index :user_page_relationships, :page_id
    remove_index :user_page_relationships, :relationship_type
    remove_index :user_page_relationships, :fb_created_time
  end

end
