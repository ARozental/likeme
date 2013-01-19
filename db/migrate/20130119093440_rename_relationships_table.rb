class RenameRelationshipsTable < ActiveRecord::Migration
  def up
    rename_table :user_page_relatioships, :user_page_relationships
  end

  def down
    rename_table :user_page_relationships, :user_page_relatioships
  end
end
