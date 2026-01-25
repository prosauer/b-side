class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  #encrypts :tidal_access_token
  #encrypts :tidal_refresh_token
  #encrypts :tidal_expires_at
  
  # Associations
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :created_groups, class_name: "Group", foreign_key: "creator_id", dependent: :destroy
  has_many :submissions, dependent: :destroy
  has_many :votes, foreign_key: "voter_id", dependent: :destroy
  has_one :tidal_account, dependent: :destroy

  # Validations
  validates :display_name, presence: true
end
