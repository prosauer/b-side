class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group

  # Enums
  enum :role, { member: 0, admin: 1 }

  # Validations
  validates :user_id, uniqueness: { scope: :group_id, message: "is already a member of this group" }
end
