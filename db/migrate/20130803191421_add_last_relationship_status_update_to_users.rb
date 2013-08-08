class AddLastRelationshipStatusUpdateToUsers < ActiveRecord::Migration
  def up
    add_column :users, :last_relationship_status_update, :timestamp
  end

  def down
    remove_column :users, :last_relationship_status_update
  end
end
