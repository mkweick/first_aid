class CreditCard < ActiveRecord::Base
  belongs_to :customer

  validates :cc_num, length: { in: 13..19 }, numericality: { only_integer: true }
  validates :cc_exp_date, length: { is: 4 }

  def encrypt_cc
    
  end

  def decrypt_cc

  end
end
