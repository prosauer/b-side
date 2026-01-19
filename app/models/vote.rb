class Vote < ApplicationRecord
  belongs_to :submission
  belongs_to :voter, class_name: "User"

  # Validations
  validates :score, presence: true, inclusion: { in: 1..10 }
  validates :voter_id, uniqueness: { scope: :submission_id, message: "can only vote once per submission" }
  validate :cannot_vote_on_own_submission

  private

  def cannot_vote_on_own_submission
    if submission && voter_id == submission.user_id
      errors.add(:voter, "cannot vote on own submission")
    end
  end
end
