module ApplicationHelper

  def leading_zero(num)
    num.to_s.strip.length == 1 ? "0#{num}" : num.to_s
  end
end