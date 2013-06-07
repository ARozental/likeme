class CreateScores < ActiveRecord::Migration
  def change
    create_table :scores do |t|
      t.column :user_id, 'BIGINT'
      t.integer :user_id, :limit => 8       
      t.column :friend_id, 'BIGINT'
      t.integer :friend_id, :limit => 8
      
      t.column :category, 'char'
      t.string :category, :limit => 1
     
      t.column :score, 'real'
      t.float :score, :limit => 4
      
      #no timestamps to save space
      #t.timestamps
    end
  end
end
