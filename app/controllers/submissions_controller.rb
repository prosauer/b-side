class SubmissionsController < ApplicationController
  before_action :set_week, only: [ :new, :create, :search, :lookup, :update ]
  before_action :set_submission, only: [ :show, :update ]
  before_action :require_group_membership
  before_action :check_submission_phase, only: [ :new, :create, :update ]

  def index
    @week = Week.find(params[:week_id])
    @submissions = @week.submissions.includes(:user, :votes)
  end

  def show
    @week = @submission.week
    @season = @week.season
    @group = @season.group
    @votes = @submission.votes.includes(:voter)
    @total_points = @votes.sum(:score)
  end

  def new
    @submission = @week.submissions.find_or_initialize_by(user: current_user)
    @season = @week.season
    @group = @season.group
  end

  def create
    existing_submission = @week.submissions.find_by(user: current_user)
    @submission = existing_submission || @week.submissions.build(user: current_user)
    @submission.assign_attributes(submission_params)
    @season = @week.season
    @group = @season.group

    if @submission.save
      redirect_to group_season_week_path(@group, @season, @week), notice: "Your submission has been saved!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @season = @week.season
    @group = @season.group

    unless @submission.user == current_user
      redirect_to group_season_week_path(@group, @season, @week),
                  alert: "You can only update your own submission."
      return
    end

    if @submission.update(submission_params)
      redirect_to group_season_week_path(@group, @season, @week), notice: "Your submission has been updated!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def search
    query = params[:query].to_s
    results = TidalService.new.search_tracks(query: query)

    render json: { tracks: results }
  end

  def lookup
    url = params[:url].to_s
    track = TidalService.new.track_from_url(url: url)

    if track
      render json: { track: track }
    else
      render json: { error: "Track not found" }, status: :not_found
    end
  end

  private

  def set_week
    @week = Week.find(params[:week_id])
  end

  def set_submission
    @submission = Submission.find(params[:id])
  end

  def submission_params
    params.require(:submission).permit(:song_title, :artist, :song_url, :comment, :tidal_id)
  end

  def require_group_membership
    if params[:week_id]
      @week = Week.find(params[:week_id])
      @group = @week.season.group
    elsif params[:id]
      @submission = Submission.find(params[:id])
      @group = @submission.week.season.group
    end

    unless @group.members.include?(current_user)
      redirect_to root_path, alert: "You must be a member of this group to access this page."
    end
  end

  def check_submission_phase
    unless @week.submission_phase?
      redirect_to group_season_week_path(@week.season.group, @week.season, @week),
                  alert: "Submissions are closed for this week."
    end
  end
end
