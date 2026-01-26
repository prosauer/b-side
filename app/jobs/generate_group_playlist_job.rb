class GenerateGroupPlaylistJob < ApplicationJob
  queue_as :default

  def perform(group_id, user_id)
    group = Group.find(group_id)
    user = User.find(user_id)
    submissions = Submission.joins(week: :season)
                            .where(seasons: { group_id: group.id })
                            .includes(:user)

    playlist_generator = PlaylistGenerator.new(user: user)
    playlist_generator.generate(
      name: "#{group.name} - All Seasons Playlist",
      tracks: submissions.map(&:tidal_id).compact
    )
  end
end
