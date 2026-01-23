class SeasonsController < ApplicationController
  before_action :set_group
  before_action :require_group_membership
  before_action :require_group_admin, only: [ :new, :create ]

  def index
    @seasons = @group.seasons.order(number: :desc)
  end

  def show
    @season = @group.seasons.find(params[:id])
    @weeks = @season.weeks.order(:number)

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

  def new
    @season = @group.seasons.build
  end

  def create
    # Get the next season number
    last_season_number = @group.seasons.maximum(:number) || 0
    @season = @group.seasons.build(
      number: last_season_number + 1,
      start_date: Date.current,
      active: true
    )

    if @season.save
      # Deactivate other seasons
      @group.seasons.where.not(id: @season.id).update_all(active: false)

      # Create 10 weeks for the season
      10.times do |i|
        week_number = i + 1
        # Each week: Monday category set, Thursday 11:59pm submission deadline, Sunday 11:59pm voting deadline
        start_of_week = @season.start_date + (i * 7).days
        submission_deadline = (start_of_week + 3.days).end_of_day  # Thursday
        voting_deadline = (start_of_week + 6.days).end_of_day      # Sunday

        @season.weeks.create!(
          number: week_number,
          category: "TBD - Set by admin",
          submission_deadline: submission_deadline,
          voting_deadline: voting_deadline
        )
      end

      redirect_to group_season_path(@group, @season), notice: "Season #{@season.number} started with 10 weeks!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end
end
