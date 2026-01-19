class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.string :invite_code
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :groups, :invite_code, unique: true
  end
end
