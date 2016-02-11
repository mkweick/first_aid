module ApplicationHelper

  def leading_zero(num)
    num.to_s.length == 1 ? "0#{num}" : num
  end
end
