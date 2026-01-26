class LikesController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_submission
  before_action :require_group_membership
  before_action :check_voting_phase

  def create
    @user_like = Like.find_or_create_by!(submission: @submission, user: current_user)
    respond_to do |format|
      format.turbo_stream { render_like_button }
      format.html { redirect_to group_season_week_path(@group, @season, @week) }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.turbo_stream do
        redirect_to group_season_week_path(@group, @season, @week), alert: e.record.errors.full_messages.join(", ")
      end
      format.html { redirect_to group_season_week_path(@group, @season, @week), alert: e.record.errors.full_messages.join(", ") }
    end
  end

  def destroy
    @user_like = Like.find_by(submission: @submission, user: current_user)
    @user_like&.destroy
    respond_to do |format|
      format.turbo_stream { render_like_button }
      format.html { redirect_to group_season_week_path(@group, @season, @week) }
    end
  end

  private

  def set_submission
    @submission = Submission.find(params[:submission_id])
    @week = @submission.week
    @season = @week.season
    @group = @season.group
  end

  def require_group_membership
    unless @group.members.include?(current_user)
      redirect_to root_path, alert: "You must be a member of this group to access this page."
    end
  end

  def check_voting_phase
    return if @week.voting_phase?

    redirect_to group_season_week_path(@group, @season, @week), alert: "Likes are only available during voting."
  end

  def render_like_button
    render turbo_stream: turbo_stream.replace(
      dom_id(@submission, :like),
      partial: "likes/button",
      locals: { submission: @submission, user_like: current_user.likes.find_by(submission: @submission) }
    )
  end
end
