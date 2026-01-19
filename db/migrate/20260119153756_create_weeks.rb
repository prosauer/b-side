class CreateWeeks < ActiveRecord::Migration[8.1]
  def change
    create_table :weeks do |t|
      t.references :season, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :category, null: false
      t.datetime :submission_deadline, null: false
      t.datetime :voting_deadline, null: false
      t.string :spotify_playlist_url
      t.string :tidal_playlist_url

      t.timestamps
    end
    add_index :weeks, [ :season_id, :number ], unique: true
  end
end
