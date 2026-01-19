class Submission < ApplicationRecord
  belongs_to :week
  belongs_to :user
  has_many :votes, dependent: :destroy

  # Validations
  validates :song_title, :artist, presence: true
  validates :user_id, uniqueness: { scope: :week_id, message: "can only submit one song per week" }
end
