module CustomerHelper
  def leading_zero(num)
    num.length == 1 ? "0#{num}" : num
  end
end
