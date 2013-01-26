class AddColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :birthday, :string
    add_column :users, :hometown, :string
    add_column :users, :quotes, :string
    add_column :users, :relationship_status, :string
    add_column :users, :significant_other, :string
  end
end
