module CustomerHelper
  def leading_zero(num)
    num.length == 1 ? "0#{num}" : num
  end

  def payment_type
    (@customer.cc_sq_num || @customer.credit_card) ? "CC" : "PO"
  end
end
