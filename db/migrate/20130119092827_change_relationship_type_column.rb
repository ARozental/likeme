class ChangeRelationshipTypeColumn < ActiveRecord::Migration
  def up
    rename_column :user_page_relatioships, :type, :relationship_type
  end

  def down
    rename_column :user_page_relatioships, :relationship_type, :type
  end
end
