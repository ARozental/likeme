class CreateAttendances < ActiveRecord::Migration
  def change
    create_table :attendances do |t|
      t.column :user_id, 'BIGINT'
      t.integer :user_id, :limit => 8, :null => false
      t.column :event_id, 'BIGINT'
      t.integer :event_id, :limit => 8, :null => false
      t.string :rsvp_status, :limit => 1

    end
    add_index :attendances, :user_id
    add_index :attendances, :rsvp_status
  end
end
