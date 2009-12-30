class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.string :vorname
      t.string :nachname
      t.string :verein
      t.string :vereins_id
      t.string :bemerkung

      t.timestamps
    end
  end

  def self.down
    drop_table :people
  end
end
