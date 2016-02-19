class Customer < ActiveRecord::Base
  belongs_to  :user
  has_many    :items,       dependent: :destroy
  has_one     :credit_card, dependent: :destroy

  validates :user_id,   presence: true
  validates :cust_num,  presence: true, uniqueness: { scope: [:ship_to_num, :user_id] }
end
