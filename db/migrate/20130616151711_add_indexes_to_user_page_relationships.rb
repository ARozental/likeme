class AddIndexesToUserPageRelationships < ActiveRecord::Migration
  def self.up
    add_index :user_page_relationships, :user_id
    add_index :user_page_relationships, :relationship_type
  end
  def self.down
    remove_index :user_page_relationships, :user_id
    remove_index :user_page_relationships, :relationship_type
  end
end
