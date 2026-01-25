class AddTidalTokensToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :tidal_access_token, :text
    add_column :users, :tidal_refresh_token, :text
    add_column :users, :tidal_expires_at, :datetime
  end
end
