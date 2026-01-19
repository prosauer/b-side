class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @groups = current_user.groups.includes(:seasons)
    @active_weeks = Week.joins(season: { group: :memberships })
                        .where(memberships: { user_id: current_user.id })
                        .where("weeks.voting_deadline > ?", Time.current)
                        .order(:submission_deadline)
  end
end
