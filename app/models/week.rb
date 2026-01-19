class Week < ApplicationRecord
  belongs_to :season
  has_many :submissions, dependent: :destroy

  # Validations
  validates :number, presence: true, uniqueness: { scope: :season_id }, inclusion: { in: 1..10 }
  validates :category, presence: true
  validates :submission_deadline, :voting_deadline, presence: true

  # Phase methods
  def submission_phase?
    Time.current < submission_deadline
  end

  def voting_phase?
    Time.current >= submission_deadline && Time.current < voting_deadline
  end

  def results_phase?
    Time.current >= voting_deadline
  end
end
