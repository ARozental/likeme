class RemoveTimestampsFromUserPageRelationship < ActiveRecord::Migration
  def up
    remove_column :user_page_relationships, :fb_created_time
    remove_column :user_page_relationships, :created_at
    remove_column :user_page_relationships, :updated_at   
  end

  def down
    add_column :user_page_relationships, :fb_created_time, :timestamp
    add_column :user_page_relationships, :created_at, :timestamp
    add_column :user_page_relationships, :updated_at, :timestamp
  end
end
