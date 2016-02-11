module CustomerHelper

  def payment_type
    (@customer.cc_sq_num || @customer.credit_card) ? "CC" : "PO"
  end
end
