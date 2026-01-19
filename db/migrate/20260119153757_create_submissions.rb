class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.references :week, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :song_title, null: false
      t.string :artist, null: false
      t.string :song_url
      t.string :spotify_uri
      t.string :tidal_id
      t.text :comment
      t.string :album_art_url

      t.timestamps
    end
    add_index :submissions, [ :week_id, :user_id ], unique: true
  end
end
