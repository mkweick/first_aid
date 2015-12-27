class Customer < ActiveRecord::Base
  belongs_to :user
  has_many :items, dependent: :destroy

  validates :cust_num, presence: true, uniqueness: true
  validates :cust_name, presence: true
  validates :user_id, presence: true
end
