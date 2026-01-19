class SendReminderJob < ApplicationJob
  queue_as :default

  def perform(week_id, reminder_type)
    week = Week.find(week_id)
    group = week.season.group
    members = group.members

    case reminder_type
    when "submission_reminder"
      # Send reminder to members who haven't submitted
      submitted_user_ids = week.submissions.pluck(:user_id)
      members_to_remind = members.where.not(id: submitted_user_ids)

      members_to_remind.each do |member|
        # TODO: Send email reminder
        # ReminderMailer.submission_reminder(member, week).deliver_later
      end

    when "voting_reminder"
      # Send reminder to all members to vote
      members.each do |member|
        # TODO: Send email reminder
        # ReminderMailer.voting_reminder(member, week).deliver_later
      end
    end
  end
end
