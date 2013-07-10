class AddLastForeginFbUpdate < ActiveRecord::Migration
  def up
    add_column :users, :last_foregin_fb_update, :timestamp
  end

  def down
    remove_column :users, :last_foregin_fb_update
  end
end
