class CreateTopArtists < ActiveRecord::Migration[5.1]
  def change
    create_table :top_artists do |t|
      t.string :genres

      t.timestamps
    end
  end
end
