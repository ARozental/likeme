class RemoveTimestampsFromPages < ActiveRecord::Migration
  def change
    remove_column :pages, :created_at
    remove_column :pages, :updated_at
  end
end
