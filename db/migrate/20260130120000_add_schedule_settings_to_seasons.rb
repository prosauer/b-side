class AddScheduleSettingsToSeasons < ActiveRecord::Migration[7.0]
  def change
    add_column :seasons, :start_at, :datetime
    add_column :seasons, :deadline_mode, :string, default: "weekdays", null: false
    add_column :seasons, :submission_weekday, :integer, default: 4, null: false
    add_column :seasons, :voting_weekday, :integer, default: 0, null: false
    add_column :seasons, :submission_interval_days, :integer, default: 3, null: false
    add_column :seasons, :submission_interval_hours, :integer, default: 0, null: false
    add_column :seasons, :voting_interval_days, :integer, default: 3, null: false
    add_column :seasons, :voting_interval_hours, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        execute "UPDATE seasons SET start_at = start_date WHERE start_at IS NULL AND start_date IS NOT NULL"
      end
    end

    change_column_null :seasons, :start_at, false
  end
end
