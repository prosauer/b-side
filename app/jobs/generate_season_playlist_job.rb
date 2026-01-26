class GenerateSeasonPlaylistJob < ApplicationJob
  queue_as :default

  def perform(season_id, user_id)
    season = Season.find(season_id)
    user = User.find(user_id)
    submissions = Submission.joins(:week)
                            .where(weeks: { season_id: season.id })
                            .where("weeks.submission_deadline <= ?", Time.current)
                            .includes(:user)

    playlist_generator = PlaylistGenerator.new(user: user)
    playlist_generator.generate(
      name: "Season #{season.number} Playlist",
      tracks: submissions.map(&:tidal_id).compact
    )
  end
end
