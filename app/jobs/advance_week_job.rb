class AdvanceWeekJob < ApplicationJob
  queue_as :default

  def perform(season_id)
    season = Season.find(season_id)
    current_week = season.weeks.order(:number).last

    # Check if we've completed all 10 weeks
    if current_week && current_week.number >= 10 && current_week.results_phase?
      # End the season
      season.update(active: false)
    elsif current_week.nil? || current_week.results_phase?
      # Create next week
      next_number = current_week ? current_week.number + 1 : 1

      # TODO: Set appropriate deadlines and category
      # This would typically be set by an admin, but here's a placeholder:
      submission_deadline = Time.current + 3.days
      voting_deadline = submission_deadline + 3.days

      Week.create!(
        season: season,
        number: next_number,
        category: "TBD - Set by admin",
        submission_deadline: submission_deadline,
        voting_deadline: voting_deadline
      )
    end
  end
end
