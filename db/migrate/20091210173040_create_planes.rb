class CreatePlanes < ActiveRecord::Migration
  def self.up
    create_table :planes do |t|
      t.text :kennzeichen
      t.string :verein
      t.text :typ
      t.int :sitze
      t.text :gattung
      t.text :wettbewerbskennzeichen
      t.text :bemerkung

      t.timestamps
    end
  end

  def self.down
    drop_table :planes
  end
end
