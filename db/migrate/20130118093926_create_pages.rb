class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      #t.integer :id, :limit => 8
      t.column :pid, 'BIGINT'#'NUMERIC(20)'
      t.integer :pid, :limit => 8 
      t.string :name
      t.string :category

      t.timestamps
    end
  #execute "ALTER TABLE users ALTER COLUMN id bigint;"
  #execute "ALTER TABLE pages ADD PRIMARY KEY (id);"
  end
end
