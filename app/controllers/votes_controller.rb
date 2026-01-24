class VotesController < ApplicationController
  before_action :set_submission, only: :create
  before_action :set_week, only: :bulk_update
  before_action :require_group_membership_for_submission, only: :create
  before_action :require_group_membership_for_week, only: :bulk_update
  before_action :check_voting_phase_for_submission, only: :create
  before_action :check_voting_phase_for_week, only: :bulk_update

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

  def bulk_update
    @season = @week.season
    @group = @season.group
    submissions = @week.submissions.includes(:user).where.not(user: current_user)
    submissions_by_id = submissions.index_by(&:id)
    votes_input = params.fetch(:votes, {}).to_unsafe_h

    desired_votes = votes_input.each_with_object({}) do |(submission_id, attrs), result|
      submission = submissions_by_id[submission_id.to_i]
      next unless submission

      score = attrs.fetch("score", 0).to_i
      comment = attrs.fetch("comment", "").to_s.strip
      score = 0 if score.negative?
      result[submission.id] = { score: score, comment: comment }
    end

    total_points = desired_votes.values.sum { |vote| vote[:score] }
    if total_points != Week::TOTAL_POINTS_PER_USER
      return redirect_to group_season_week_path(@group, @season, @week),
                         alert: "Please allocate all #{Week::TOTAL_POINTS_PER_USER} points before submitting."
    end

    max_per_song = @group.max_points_per_song
    if desired_votes.values.any? { |vote| vote[:score] > max_per_song }
      return redirect_to group_season_week_path(@group, @season, @week),
                         alert: "You can give up to #{max_per_song} points per song."
    end

    Vote.transaction do
      desired_votes.each do |submission_id, vote_data|
        vote = Vote.find_by(submission_id: submission_id, voter: current_user)
        if vote_data[:score].positive?
          if vote
            vote.update!(score: vote_data[:score], comment: vote_data[:comment])
          else
            Vote.create!(
              submission_id: submission_id,
              voter: current_user,
              score: vote_data[:score],
              comment: vote_data[:comment]
            )
          end
        else
          vote&.destroy!
        end
      end
    end

    redirect_to group_season_week_path(@group, @season, @week), notice: "Your votes have been updated."
  end

  private

  def set_submission
    @submission = Submission.find(params[:submission_id])
  end

  def set_week
    @week = Week.find(params[:week_id])
  end

  def vote_params
    params.fetch(:vote, {}).permit(:comment)
  end

  def require_group_membership_for_submission
    @group = @submission.week.season.group
    unless @group.members.include?(current_user)
      redirect_to root_path, alert: "You must be a member of this group to access this page."
    end
  end

  def require_group_membership_for_week
    @group = @week.season.group
    unless @group.members.include?(current_user)
      redirect_to root_path, alert: "You must be a member of this group to access this page."
    end
  end

  def check_voting_phase_for_submission
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

  def check_voting_phase_for_week
    unless @week.voting_phase?
      redirect_to group_season_week_path(@week.season.group, @week.season, @week),
                  alert: "Voting is not open for this week."
    end
  end

  def remaining_points_for_week
    used_points = current_user.votes.joins(:submission).where(submissions: { week_id: @week.id }).sum(:score)
    Week::TOTAL_POINTS_PER_USER - used_points
  end
end
