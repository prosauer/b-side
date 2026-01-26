class PlaylistGenerator
  def initialize(user:)
    @user = user
  end

  def generate(name:, tracks:, week: nil)
    existing_playlist = UserPlaylist.find_by(user: @user, name: name)
    tidal_account = @user.tidal_account
    tidal_service = TidalService.new
    access_token = ensure_tidal_access_token(tidal_service, tidal_account) if tidal_account

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

  def ensure_tidal_access_token(service, tidal_account)
    return tidal_account.access_token unless tidal_account.expired? && tidal_account.refresh_token.present?

    token_data = service.refresh_access_token(refresh_token: tidal_account.refresh_token)
    return unless token_data

    tidal_account.update!(
      access_token: token_data["access_token"],
      refresh_token: token_data["refresh_token"].presence || tidal_account.refresh_token,
      expires_at: token_data["expires_in"] ? Time.current + token_data["expires_in"].to_i.seconds : nil
    )
    tidal_account.access_token
  end
end
