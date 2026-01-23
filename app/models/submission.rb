class Submission < ApplicationRecord
  belongs_to :week
  belongs_to :user
  has_many :votes, dependent: :destroy

  # Validations
  validates :song_title, :artist, presence: true
  validates :user_id, uniqueness: { scope: :week_id, message: "can only submit one song per week" }
  validate :song_url_must_be_safe

  # Instance methods
  def total_points
    votes.sum(:score)
  end

  private

  def song_url_must_be_safe
    return if song_url.blank?

    uri = URI.parse(song_url) rescue nil
    unless uri && uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:song_url, "must be a valid http(s) URL")
    end
  end
end
