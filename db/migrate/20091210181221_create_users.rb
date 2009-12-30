class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.text :username
      t.text :password
      t.text :club

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
