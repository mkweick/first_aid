class User < ActiveRecord::Base
  has_many :customers, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, length: { minimum: 4 }, on: :create
  validates :whs_id, length: { in: 1..2 }, numericality: { only_integer: true }

  def first_name=(fn)
    write_attribute(:first_name, fn.capitalize)
  end

  def last_name=(ln)
    write_attribute(:last_name, ln.capitalize)
  end
end
