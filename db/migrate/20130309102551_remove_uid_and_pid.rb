class RemoveUidAndPid < ActiveRecord::Migration
  def up
    remove_column :users, :uid
    remove_column :pages, :pid
  
  end

  def down
    add_column :users, :uid, 'BIGINT'
    add_column :pages, :pid, 'BIGINT'
  end

end
