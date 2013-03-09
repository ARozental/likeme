class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t| #do I need ", :id => false" here?
      #t.integer :id, :limit => 8
      t.string :provider
      t.column :uid, 'BIGINT'#'NUMERIC(20)'
      t.integer :uid, :limit => 8 
      t.string :name
      t.string :oauth_token
      t.datetime :oauth_expires_at

      t.timestamps
    end
    #execute "ALTER TABLE users ALTER COLUMN id bigint;"
    #execute "ALTER TABLE users ADD PRIMARY KEY (uid);"
  end
end
