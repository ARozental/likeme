class CreateUserPageRelatioships < ActiveRecord::Migration
  def change
    create_table :user_page_relatioships do |t|
      t.integer :user_id
      t.integer :page_id
      t.string :type
      t.datetime :fb_created_time

      t.timestamps
    end
  end
end
