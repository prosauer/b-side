class Vote < ApplicationRecord
  belongs_to :submission
  belongs_to :voter, class_name: "User"

  # Validations
  validates :score, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :voter_id, uniqueness: { scope: :submission_id, message: "can only vote once per submission" }
  validate :cannot_vote_on_own_submission
  validate :score_within_song_limit
  validate :total_points_within_week

  private

  def cannot_vote_on_own_submission
    if submission && voter_id == submission.user_id
      errors.add(:voter, "cannot vote on own submission")
    end
  end

  def score_within_song_limit
    return unless submission && score

    max_points = submission.week.season.group.max_points_per_song
    if score > max_points
      errors.add(:score, "cannot exceed #{max_points} points for a single song")
    end
  end

  def total_points_within_week
    return unless submission && voter && score

    week = submission.week
    other_votes_total = Vote.joins(:submission)
                             .where(voter_id: voter_id, submissions: { week_id: week.id })
                             .where.not(id: id)
                             .sum(:score)
    if other_votes_total + score > Week::TOTAL_POINTS_PER_USER
      errors.add(:score, "cannot exceed #{Week::TOTAL_POINTS_PER_USER} total points for the week")
    end
  end
end
