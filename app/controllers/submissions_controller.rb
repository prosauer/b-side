class SubmissionsController < ApplicationController
  before_action :set_week, only: [ :new, :create ]
  before_action :set_submission, only: [ :show ]
  before_action :require_group_membership
  before_action :check_submission_phase, only: [ :new, :create ]

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
    @submission = @week.submissions.build
    @season = @week.season
    @group = @season.group
  end

  def create
    @submission = @week.submissions.build(submission_params)
    @submission.user = current_user
    @season = @week.season
    @group = @season.group

    if @submission.save
      redirect_to group_season_week_path(@group, @season, @week), notice: "Your submission has been saved!"
    else
      render :new, status: :unprocessable_entity
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
    params.require(:submission).permit(:song_title, :artist, :song_url, :comment)
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

    if @week.submissions.exists?(user: current_user)
      redirect_to group_season_week_path(@week.season.group, @week.season, @week),
                  alert: "You have already submitted for this week."
    end
  end
end
