class Pk < ActiveRecord::Migration
  def up
    #execute "ALTER TABLE users ADD PRIMARY KEY (id);"
    #execute "ALTER TABLE pages ADD PRIMARY KEY (id);"
    execute "ALTER TABLE users MODIFY id INT(20) NOT NULL;"
    execute "ALTER TABLE pages MODIFY id INT(20) NOT NULL;"
    execute "ALTER TABLE users MODIFY uid INT(20) NOT NULL;"
    execute "ALTER TABLE pages MODIFY pid INT(20) NOT NULL;"
  end

  def down

  end
end
