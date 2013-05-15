class AddBioToUsers < ActiveRecord::Migration
  def change
    add_column :users, :bio, :text, :limit => nil
  end
end
