class Group < ApplicationRecord
  belongs_to :creator, class_name: "User"
  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :seasons, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :invite_code, uniqueness: true, allow_nil: true
  validates :max_points_per_song, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than_or_equal_to: Week::TOTAL_POINTS_PER_USER
  }

  # Token generation
  has_secure_token :invite_code
end
