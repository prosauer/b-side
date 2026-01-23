class AddMaxPointsPerSongToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :max_points_per_song, :integer, null: false, default: 3
  end
end
