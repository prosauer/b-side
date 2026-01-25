class WeeksController < ApplicationController
  before_action :set_week
  before_action :require_group_membership
  before_action :require_group_admin, only: [ :edit, :update ]

  def index
    @season = Season.find(params[:season_id])
    @weeks = @season.weeks.order(:number)
  end

  def show
    @season = @week.season
    @group = @season.group
    @submissions = @week.submissions.includes(:user, :votes)
    @user_submission = @week.submissions.find_by(user: current_user)

    # For voting phase, get submissions the user hasn't voted on yet (excluding their own)
    if @week.voting_phase?
      @submissions_to_vote = @submissions.where.not(user: current_user)
      @user_votes = current_user.votes.joins(:submission)
                               .where(submissions: { week_id: @week.id })
                               .index_by(&:submission_id)
      @points_used = @user_votes.values.sum(&:score)
      @remaining_points = [Week::TOTAL_POINTS_PER_USER - @points_used, 0].max
    end
  end

  def edit
    @season = @week.season
    @group = @season.group
  end

  def update
    if @week.update(week_params)
      redirect_to group_season_week_path(@week.season.group, @week.season, @week), notice: "Week updated."
    else
      @season = @week.season
      @group = @season.group
      render :edit, status: :unprocessable_entity
    end
  end

  def generate_playlist
    unless @week.voting_phase?
      redirect_to group_season_week_path(@week.season.group, @week.season, @week),
                  alert: "Playlists can only be generated while voting is open."
      return
    end

    tidal_url = GeneratePlaylistsJob.perform_now(@week.id, current_user.id)
    if tidal_url.present?
      redirect_to tidal_url, allow_other_host: true
    else
      redirect_to group_season_week_path(@week.season.group, @week.season, @week),
                  alert: "Unable to create a playlist right now."
    end
  end

  private

  def set_week
    @week = Week.find(params[:id])
  end

  def week_params
    params.require(:week).permit(:category, :submission_deadline, :voting_deadline)
  end

  def require_group_admin
    @week = Week.find(params[:id])
    @group = @week.season.group
    membership = @group.memberships.find_by(user: current_user)
    unless membership&.admin?
      redirect_to root_path, alert: "You must be an admin of this group to perform this action."
    end
  end

  def require_group_membership
    @week = Week.find(params[:id])
    @group = @week.season.group
    unless @group.members.include?(current_user)
      redirect_to root_path, alert: "You must be a member of this group to access this page."
    end
  end
end
