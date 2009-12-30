class CreateFlights < ActiveRecord::Migration
  def self.up
    create_table :flights do |t|
      t.text :startort
      t.text :zielort
      t.int :anzahl_landungen
      t.datetime :startzeit
      t.datetime :landezeit
      t.int :typ

      t.timestamps
    end
  end

  def self.down
    drop_table :flights
  end
end
