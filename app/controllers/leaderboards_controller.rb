class LeaderboardsController < ApplicationController
  before_action :set_group
  before_action :require_group_membership

  def weekly
    @week = Week.find(params[:week_id])
    @season = @week.season

    # Calculate rankings for the week
    @rankings = @week.submissions.includes(:user, :votes).map do |submission|
      {
        submission: submission,
        user: submission.user,
        total_points: submission.votes.sum(:score)
      }
    end.sort_by { |r| -r[:total_points] }
  end

  def season
    @season = Season.find(params[:season_id])

    # Calculate cumulative standings for the season
    submissions = Submission.joins(:week).where(weeks: { season_id: @season.id }).includes(:user, :votes)

    user_stats = {}
    submissions.each do |submission|
      user_id = submission.user_id
      user_stats[user_id] ||= {
        user: submission.user,
        total_score: 0,
        games_played: 0,
        average_score: 0
      }

      points = submission.votes.sum(:score)
      user_stats[user_id][:total_score] += points
      user_stats[user_id][:games_played] += 1
    end

    # Calculate averages
    user_stats.each do |user_id, stats|
      stats[:average_score] = stats[:games_played] > 0 ? (stats[:total_score] / stats[:games_played]).round(2) : 0
    end

    @rankings = user_stats.values.sort_by { |s| -s[:total_score] }
  end

  def all_time
    # Calculate all-time standings across all seasons in the group
    submissions = Submission.joins(week: :season).where(seasons: { group_id: @group.id }).includes(:user, :votes)

    user_stats = {}
    submissions.each do |submission|
      user_id = submission.user_id
      user_stats[user_id] ||= {
        user: submission.user,
        total_score: 0,
        games_played: 0,
        average_score: 0,
        seasons_played: Set.new
      }

      points = submission.votes.sum(:score)
      user_stats[user_id][:total_score] += points
      user_stats[user_id][:games_played] += 1
      user_stats[user_id][:seasons_played] << submission.week.season_id
    end

    # Calculate averages and convert set to count
    user_stats.each do |user_id, stats|
      stats[:average_score] = stats[:games_played] > 0 ? (stats[:total_score] / stats[:games_played]).round(2) : 0
      stats[:seasons_played] = stats[:seasons_played].size
    end

    @rankings = user_stats.values.sort_by { |s| -s[:total_score] }
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def require_group_membership
    unless @group.members.include?(current_user)
      redirect_to root_path, alert: "You must be a member of this group to access this page."
    end
  end
end
