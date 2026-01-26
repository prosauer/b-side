class GeneratePlaylistsJob < ApplicationJob
  queue_as :default

  def perform(week_id, user_id)
    week = Week.find(week_id)
    user = User.find(user_id)
    submissions = week.submissions.includes(:user)

    playlist_generator = PlaylistGenerator.new(user: user)
    playlist_generator.generate(
      name: week.category,
      tracks: submissions.map(&:tidal_id).compact,
      week: week
    )
  end
end
