class SeasonsController < ApplicationController
  before_action :set_group
  before_action :require_group_membership
  before_action :require_group_admin, only: [ :new, :create, :edit, :update ]

  def index
    @seasons = @group.seasons.order(number: :desc)
  end

  def show
    @season = @group.seasons.find(params[:id])
    @weeks = @season.weeks.order(:number)
    @membership = @group.memberships.find_by(user: current_user)

    # Calculate cumulative standings for the season
    submissions = Submission.joins(:week)
                            .where(weeks: { season_id: @season.id })
                            .where("weeks.voting_deadline <= ?", Time.current)
                            .includes(:user, :votes)

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

  def generate_playlist
    season = @group.seasons.find(params[:id])
    tidal_url = GenerateSeasonPlaylistJob.perform_now(season.id, current_user.id)
    if tidal_url.present?
      redirect_to tidal_url, allow_other_host: true
    else
      redirect_to group_season_path(@group, season),
                  alert: "Unable to create a playlist right now."
    end
  end

  def new
    @season = @group.seasons.build
  end

  def create
    # Get the next season number
    last_season_number = @group.seasons.maximum(:number) || 0
    @season = @group.seasons.build(
      number: last_season_number + 1,
      start_at: Time.current,
      active: true
    )

    if @season.save
      # Deactivate other seasons
      @group.seasons.where.not(id: @season.id).update_all(active: false)

      # Create 10 weeks for the season
      prev_voting_deadline = nil
      10.times do |i|
        week_number = i + 1
        deadlines, prev_voting_deadline = compute_week_deadlines(
          @season.start_at,
          week_number,
          schedule_settings(@season),
          prev_voting_deadline
        )

        @season.weeks.create!(
          number: week_number,
          category: "TBD - Set by admin",
          subtitle: "Set by admin",
          submission_deadline: deadlines[:submission_deadline],
          voting_deadline: deadlines[:voting_deadline]
        )
      end

      redirect_to group_season_path(@group, @season), notice: "Season #{@season.number} started with 10 weeks!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @season = @group.seasons.find(params[:id])
  end

  def update
    @season = @group.seasons.find(params[:id])
    previous_start_at = @season.start_at
    previous_settings = schedule_settings(@season)

    if @season.update(season_params)
      start_at_changed = previous_start_at != @season.start_at
      settings_changed = previous_settings != schedule_settings(@season)

      if start_at_changed || settings_changed
        apply_schedule_updates(@season, previous_settings, start_at_changed)
      end

      redirect_to group_season_path(@group, @season), notice: "Season settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def season_params
    params.require(:season).permit(
      :start_at,
      :deadline_mode,
      :submission_weekday,
      :voting_weekday,
      :submission_interval_days,
      :submission_interval_hours,
      :voting_interval_days,
      :voting_interval_hours
    )
  end

  def schedule_settings(season)
    {
      deadline_mode: season.deadline_mode,
      submission_weekday: season.submission_weekday,
      voting_weekday: season.voting_weekday,
      submission_interval_days: season.submission_interval_days,
      submission_interval_hours: season.submission_interval_hours,
      voting_interval_days: season.voting_interval_days,
      voting_interval_hours: season.voting_interval_hours
    }
  end

  def apply_schedule_updates(season, previous_settings, start_at_changed)
    now = Time.current
    prev_voting_deadline = nil
    season.weeks.order(:number).each do |week|
      submission_open = week.submission_deadline > now
      settings = submission_open ? schedule_settings(season) : previous_settings
      should_update = start_at_changed || submission_open

      if should_update
        deadlines, prev_voting_deadline = compute_week_deadlines(
          season.start_at,
          week.number,
          settings,
          prev_voting_deadline
        )
        week.update!(
          submission_deadline: deadlines[:submission_deadline],
          voting_deadline: deadlines[:voting_deadline]
        )
      else
        prev_voting_deadline = week.voting_deadline
      end
    end
  end

  def compute_week_deadlines(start_at, week_number, settings, previous_voting_deadline)
    if settings[:deadline_mode] == "weekdays"
      week_start = start_at + (week_number - 1).weeks
      submission_deadline = weekday_time_for_week(week_start, settings[:submission_weekday], start_at)
      voting_deadline = weekday_time_for_week(week_start, settings[:voting_weekday], start_at)
      voting_deadline += 7.days if voting_deadline <= submission_deadline
    else
      base = previous_voting_deadline || start_at
      submission_deadline = base +
                            settings[:submission_interval_days].days +
                            settings[:submission_interval_hours].hours
      voting_deadline = submission_deadline +
                        settings[:voting_interval_days].days +
                        settings[:voting_interval_hours].hours
    end

    {
      submission_deadline: submission_deadline,
      voting_deadline: voting_deadline
    }.then { |deadlines| [deadlines, deadlines[:voting_deadline]] }
  end

  def weekday_time_for_week(week_start, target_wday, time_source)
    days_ahead = (target_wday - week_start.wday) % 7
    date = week_start.to_date + days_ahead.days
    Time.zone.local(
      date.year,
      date.month,
      date.day,
      time_source.hour,
      time_source.min,
      time_source.sec
    )
  end
end
