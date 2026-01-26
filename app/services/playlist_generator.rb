class PlaylistGenerator
  def initialize(user:)
    @user = user
  end

  def generate(name:, tracks:, week: nil)
    existing_playlist = UserPlaylist.find_by(user: @user, name: name)
    tidal_account = @user.tidal_account
    tidal_service = TidalService.new
    access_token = tidal_service.access_token_for(tidal_account) if tidal_account

    if existing_playlist
      playlist_id = extract_playlist_id(existing_playlist.tidal_url)
      if access_token.present? && playlist_id.present? && tidal_service.playlist_exists?(playlist_id, access_token: access_token)
        if week && week.tidal_playlist_url.blank?
          week.update(tidal_playlist_url: existing_playlist.tidal_url)
        end
        return existing_playlist.tidal_url
      end

      return existing_playlist.tidal_url if access_token.blank?

      existing_playlist.destroy!
    end

    return if tracks.empty?
    return unless access_token

    tidal_url = tidal_service.create_playlist(
      name: name,
      tracks: tracks,
      access_token: access_token
    )
    return unless tidal_url

    week&.update(tidal_playlist_url: tidal_url)
    UserPlaylist.create!(user: @user, week: week, name: name, tidal_url: tidal_url)

    tidal_url
  end

  private

  def extract_playlist_id(url)
    match = url.to_s.match(%r{playlist/([a-zA-Z0-9\-]+)})
    match ? match[1] : nil
  end

end
