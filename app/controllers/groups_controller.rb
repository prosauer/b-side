class GroupsController < ApplicationController
  before_action :set_group, only: [ :show, :edit, :update, :destroy ]
  before_action :require_group_membership, only: [ :show, :generate_playlist ]
  before_action :require_group_admin, only: [ :edit, :update, :destroy ]

  def index
    @groups = current_user.groups.includes(:members, :seasons)
  end

  def show
    @current_season = @group.seasons.active.first
    @members = @group.members
    @membership = @group.memberships.find_by(user: current_user)
  end

  def generate_playlist
    tidal_url = GenerateGroupPlaylistJob.perform_now(@group.id, current_user.id)
    if tidal_url.present?
      redirect_to tidal_url, allow_other_host: true
    else
      redirect_to group_path(@group),
                  alert: "Unable to create a playlist right now."
    end
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    @group.creator = current_user

    if @group.save
      # Create admin membership for creator
      @group.memberships.create!(user: current_user, role: :admin)
      redirect_to @group, notice: "Group was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @group.update(group_params)
      redirect_to @group, notice: "Group was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_path, notice: "Group was successfully deleted."
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :max_points_per_song)
  end
end
