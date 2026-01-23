class VotesController < ApplicationController
  before_action :set_submission
  before_action :require_group_membership
  before_action :check_voting_phase

  def create
    @week = @submission.week
    @season = @week.season
    @group = @season.group
    existing_vote = Vote.find_by(submission: @submission, voter: current_user)

    if existing_vote
      existing_vote.score += 1
      @vote = existing_vote
      success_message = "Point added!"
    else
      @vote = @submission.votes.build(vote_params.merge(score: 1))
      @vote.voter = current_user
      success_message = "Your vote has been recorded!"
    end

    if @vote.save
      redirect_to group_season_week_path(@group, @season, @week), notice: success_message
    else
      redirect_to group_season_week_path(@group, @season, @week),
                  alert: @vote.errors.full_messages.join(", ")
    end
  end

  private

  def set_submission
    @submission = Submission.find(params[:submission_id])
  end

  def vote_params
    params.require(:vote).permit(:comment)
  end

  def require_group_membership
    @group = @submission.week.season.group
    unless @group.members.include?(current_user)
      redirect_to root_path, alert: "You must be a member of this group to access this page."
    end
  end

  def check_voting_phase
    @week = @submission.week
    unless @week.voting_phase?
      redirect_to group_season_week_path(@week.season.group, @week.season, @week),
                  alert: "Voting is not open for this week."
    end

    if @week.submissions.exists?(user: current_user, id: @submission.id)
      redirect_to group_season_week_path(@week.season.group, @week.season, @week),
                  alert: "You cannot vote on your own submission."
    end
    if remaining_points_for_week <= 0
      redirect_to group_season_week_path(@week.season.group, @week.season, @week),
                  alert: "You have already used all #{Week::TOTAL_POINTS_PER_USER} points for this week."
    end
  end

  def remaining_points_for_week
    used_points = current_user.votes.joins(:submission).where(submissions: { week_id: @week.id }).sum(:score)
    Week::TOTAL_POINTS_PER_USER - used_points
  end
end
