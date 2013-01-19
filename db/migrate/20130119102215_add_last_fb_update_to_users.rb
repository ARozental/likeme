class AddLastFbUpdateToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_fb_update, :timestamp
  end
end
