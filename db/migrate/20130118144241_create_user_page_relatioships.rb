class CreateUserPageRelatioships < ActiveRecord::Migration
  def change
    create_table :user_page_relatioships do |t|
      t.column :user_id, 'BIGINT UNSIGNED'
      t.integer :user_id, :limit => 8, :null => false
      t.column :page_id, 'BIGINT UNSIGNED'
      t.integer :page_id, :limit => 8, :null => false
      t.string :type
      t.datetime :fb_created_time

      t.timestamps
    end
  end
end
