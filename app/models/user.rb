class User < ActiveRecord::Base
  has_many :customers

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, length: { minimum: 4 }
  validates :whs_id, presence: true
end
