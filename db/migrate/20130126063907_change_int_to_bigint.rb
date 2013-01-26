class ChangeIntToBigint < ActiveRecord::Migration
#do it in create stage?
=begin
  def up
    change_column :users, :id, :int, :limit => 8
    change_column :users, :uid, :int, :limit => 8
    change_column :pages, :id, :int, :limit => 8
    change_column :pages, :pid, :int, :limit => 8
    change_column :user_page_relationships, :user_id, :int, :limit => 8
    change_column :user_page_relationships, :page_id, :int, :limit => 8

  end

  def down
    change_column :users, :id, :int
    change_column :users, :uid, :int
    change_column :pages, :id, :int
    change_column :pages, :pid, :int
    change_column :user_page_relationships
    change_column :user_page_relationships
  end
=end
end
