class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!, unless: :devise_controller?

  private

  def require_group_membership
    @group = Group.find(params[:group_id] || params[:id])
    unless @group.members.include?(current_user)
      redirect_to root_path, alert: "You must be a member of this group to access this page."
    end
  end

  def require_group_admin
    @group = Group.find(params[:group_id] || params[:id])
    membership = @group.memberships.find_by(user: current_user)
    unless membership&.admin?
      redirect_to root_path, alert: "You must be an admin of this group to perform this action."
    end
  end
end
