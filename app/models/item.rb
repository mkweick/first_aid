class Item < ActiveRecord::Base
  belongs_to :customer

  validates :kit,             presence: true
  validates :item_num,        presence: true
  validates :item_desc,       presence: true
  validates :item_qty,        presence: true, numericality: { greater_than: 0 }
  validates :item_price,      presence: true
  validates :item_price_type, presence: true
end
