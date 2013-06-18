class AddIndexesToScores < ActiveRecord::Migration
  def change
    add_index :scores, :user_id
    add_index :scores, :category
    add_index :scores, :score
  end
end
