class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.integer :pid
      t.string :name
      t.string :category

      t.timestamps
    end
  end
end
