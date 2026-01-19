class Season < ApplicationRecord
  belongs_to :group
  has_many :weeks, dependent: :destroy

  # Validations
  validates :number, presence: true, uniqueness: { scope: :group_id }
  validates :start_date, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
end
