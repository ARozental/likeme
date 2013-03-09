class CreateFriendships < ActiveRecord::Migration
  def up
    create_table 'friendships', :id => false do |t|      
      t.column :user_id, 'BIGINT'
      t.integer :user_id, :limit => 8, :null => false
      t.column :friend_id, 'BIGINT'
      t.integer :friend_id, :limit => 8, :null => false      
    end
  end

  def down
    drop_table 'friendships'
  end  
end
