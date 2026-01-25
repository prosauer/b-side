class GeneratePlaylistsJob < ApplicationJob
  queue_as :default

  def perform(week_id, user_id)
    week = Week.find(week_id)
    user = User.find(user_id)
    submissions = week.submissions.includes(:user)

    return if submissions.empty?

    # Generate Spotify playlist
    spotify_service = SpotifyService.new
    spotify_url = spotify_service.create_playlist(
      name: week.category,
      tracks: submissions.map(&:spotify_uri).compact
    )
    week.update(spotify_playlist_url: spotify_url) if spotify_url

    # Generate Tidal playlist
    tidal_account = user.tidal_account
    return unless tidal_account

    tidal_service = TidalService.new
    access_token = ensure_tidal_access_token(tidal_service, tidal_account)
    return unless access_token

    tidal_url = tidal_service.create_playlist(
      name: week.category,
      tracks: submissions.map(&:tidal_id).compact,
      access_token: access_token
    )
    week.update(tidal_playlist_url: tidal_url) if tidal_url
    tidal_url
  end

  private

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
