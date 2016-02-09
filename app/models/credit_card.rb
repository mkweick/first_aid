class CreditCard < ActiveRecord::Base
  belongs_to :customer

  before_save :encrypt

  validates :cc_num,  length: { in: 15..18, too_short: 'too short (min is 15)',
                                            too_long: 'too long (max is 18)' }
  validates :cc_exp_mth, presence: true
  validates :cc_exp_year, presence: true

  def decrypt
    decrypted_card = ''
    self.cc_num.strip.each_char.with_index do |char, idx|
      number = cc_cipher.index(char) - (idx * 2)
      decrypted_card << number.to_s
    end
    self.cc_num = decrypted_card
    decrypted_card
  end

  private

  def encrypt
    encrypted_card = ''
    self.cc_num.strip.each_char.with_index do |num, idx|
      index = (idx * 2) + num.to_i
      encrypted_card << cc_cipher[index]
    end
    self.cc_num = encrypted_card
  end

  def cc_cipher
    [
      '2','U','@','!','x','M','Y','k','D','6','d','m','C','s','4','b','H','z',
      '9','&','P','G','7','K','A','N','E','3','Q','J','B','#','c','j','0','R',
      'a','u','I','h','q','y','o','r','T','v','X','1','V','i','S','Z','O','L',
      'f','w','t','F','e','$','W','5','p','l','n','8','g'
    ]
  end
end
