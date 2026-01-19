class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :voter, null: false, foreign_key: { to_table: :users }
      t.integer :score, null: false
      t.text :comment

      t.timestamps
    end
    add_index :votes, [ :submission_id, :voter_id ], unique: true
  end
end
