class InvitesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]

  def show
    @group = Group.find_by!(invite_code: params[:invite_code])
    @already_member = current_user && @group.members.include?(current_user)
  end

  def accept
    @group = Group.find_by!(invite_code: params[:invite_code])

    if @group.members.include?(current_user)
      redirect_to @group, notice: "You are already a member of this group."
    else
      @group.memberships.create!(user: current_user, role: :member)
      redirect_to @group, notice: "Welcome to #{@group.name}!"
    end
  end
end
