class GeneratePlaylistsJob < ApplicationJob
  queue_as :default

  def perform(week_id)
    week = Week.find(week_id)
    submissions = week.submissions.includes(:user)

    return if submissions.empty?

    # Generate Spotify playlist
    spotify_service = SpotifyService.new
    spotify_url = spotify_service.create_playlist(
      name: "#{week.season.group.name} - Week #{week.number}: #{week.category}",
      tracks: submissions.map(&:spotify_uri).compact
    )
    week.update(spotify_playlist_url: spotify_url) if spotify_url

    # Generate Tidal playlist
    tidal_service = TidalService.new
    tidal_url = tidal_service.create_playlist(
      name: "#{week.season.group.name} - Week #{week.number}: #{week.category}",
      tracks: submissions.map(&:tidal_id).compact
    )
    week.update(tidal_playlist_url: tidal_url) if tidal_url
  end
end
