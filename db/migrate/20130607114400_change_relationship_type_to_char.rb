class ChangeRelationshipTypeToChar < ActiveRecord::Migration
  def change
    remove_column :user_page_relationships, :relationship_type
    add_column :user_page_relationships, :relationship_type, "char"
  end
end
