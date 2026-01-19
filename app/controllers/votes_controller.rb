class VotesController < ApplicationController
  before_action :set_submission
  before_action :require_group_membership
  before_action :check_voting_phase

  def create
    @vote = @submission.votes.build(vote_params)
    @vote.voter = current_user
    @week = @submission.week
    @season = @week.season
    @group = @season.group

    if @vote.save
      redirect_to group_season_week_path(@group, @season, @week), notice: "Your vote has been recorded!"
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
    params.require(:vote).permit(:score, :comment)
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

    if Vote.exists?(submission: @submission, voter: current_user)
      redirect_to group_season_week_path(@week.season.group, @week.season, @week),
                  alert: "You have already voted on this submission."
    end
  end
end
