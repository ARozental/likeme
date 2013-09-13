class AddDetailsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :details, :text, :limit => nil
  end
end
