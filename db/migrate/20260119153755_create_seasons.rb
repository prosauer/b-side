class CreateSeasons < ActiveRecord::Migration[8.1]
  def change
    create_table :seasons do |t|
      t.references :group, null: false, foreign_key: true
      t.integer :number, null: false
      t.boolean :active, default: false
      t.date :start_date

      t.timestamps
    end
    add_index :seasons, [ :group_id, :number ], unique: true
  end
end
