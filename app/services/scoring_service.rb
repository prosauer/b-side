# Service to calculate scores from votes
class ScoringService
  def self.calculate_submission_score(submission)
    votes = submission.votes
    return 0 if votes.empty?

    votes.sum(:score)
  end

  def self.calculate_weekly_scores(week)
    # Calculate scores for all submissions in a week
    scores = {}
    week.submissions.includes(:votes).each do |submission|
      scores[submission.id] = calculate_submission_score(submission)
    end
    scores
  end

  def self.calculate_season_standings(season)
    # Calculate cumulative scores across all weeks in a season
    standings = Hash.new(0)

    season.weeks.includes(submissions: :votes).each do |week|
      weekly_scores = calculate_weekly_scores(week)
      week.submissions.each do |submission|
        standings[submission.user_id] += weekly_scores[submission.id]
      end
    end

    standings
  end
end
