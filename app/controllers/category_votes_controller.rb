class CategoryVotesController < ApplicationController
  before_action :set_category_submission
  before_action :require_group_membership_for_group

  def create
    vote = @category_submission.category_votes.build(voter: current_user)
    if vote.save
      redirect_to group_path(@group), notice: "Vote recorded."
    else
      redirect_to group_path(@group), alert: vote.errors.full_messages.to_sentence
    end
  end

  def destroy
    vote = @category_submission.category_votes.find_by(id: params[:id], voter: current_user)
    if vote&.destroy
      redirect_to group_path(@group), notice: "Vote removed."
    else
      redirect_to group_path(@group), alert: "Unable to remove vote."
    end
  end

  private

  def set_category_submission
    @category_submission = CategorySubmission.find(params[:category_submission_id])
    @group = @category_submission.group
  end

  def require_group_membership_for_group
    unless @group.members.include?(current_user)
      redirect_to root_path, alert: "You must be a member of this group to access this page."
    end
  end
end
