class Season < ApplicationRecord
  belongs_to :group
  has_many :weeks, dependent: :destroy

  DEADLINE_MODES = %w[weekdays intervals].freeze

  # Validations
  validates :number, presence: true, uniqueness: { scope: :group_id }
  validates :start_date, presence: true
  validates :start_at, presence: true
  validates :deadline_mode, inclusion: { in: DEADLINE_MODES }
  validates :submission_weekday, :voting_weekday, inclusion: { in: 0..6 }
  validates :submission_interval_days, :submission_interval_hours, :voting_interval_days, :voting_interval_hours,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }

  before_validation :sync_start_dates

  # Scopes
  scope :active, -> { where(active: true) }

  private

  def sync_start_dates
    if start_at.present?
      self.start_date = start_at.to_date
    elsif start_date.present?
      self.start_at = start_date.in_time_zone
    end
  end
end
