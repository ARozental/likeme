class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :name
      t.timestamp :start_time
      t.timestamp :end_time
      t.string :location

    end
    add_index :events, :end_time
    add_index :events, :location
  end
end
