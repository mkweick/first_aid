module CreditCardHelper

  def cc_type_name(cc_code)
    case cc_code
    when 'AM' then 'American Express'
    when 'MC' then 'MasterCard'
    when 'VI' then 'Visa'
    when 'DS' then 'Discover'
    when 'CC' then 'N/A'
    when '1' then 'N/A'
    when '2' then 'N/A'
    end
  end

  def cc_format_exp_date(num)
    date = num.length == 3 ? "0#{num}" : num
    date.insert(2, '/' + Time.now.strftime("%Y")[0..1])
  end

  def cc_months
    ['01','02','03','04','05','06','07','08','09','10','11','12']
  end

  def cc_years
    year_today = Date.today.strftime("%y").to_i
    year_today.upto(year_today + 15).map{ |y| ["20#{y}", "#{y}"] }
  end

  def us_states
    [
      ['AK', 'AK'],
      ['AL', 'AL'],
      ['AR', 'AR'],
      ['AZ', 'AZ'],
      ['CA', 'CA'],
      ['CO', 'CO'],
      ['CT', 'CT'],
      ['DC', 'DC'],
      ['DE', 'DE'],
      ['FL', 'FL'],
      ['GA', 'GA'],
      ['HI', 'HI'],
      ['IA', 'IA'],
      ['ID', 'ID'],
      ['IL', 'IL'],
      ['IN', 'IN'],
      ['KS', 'KS'],
      ['KY', 'KY'],
      ['LA', 'LA'],
      ['MA', 'MA'],
      ['MD', 'MD'],
      ['ME', 'ME'],
      ['MI', 'MI'],
      ['MN', 'MN'],
      ['MO', 'MO'],
      ['MS', 'MS'],
      ['MT', 'MT'],
      ['NC', 'NC'],
      ['ND', 'ND'],
      ['NE', 'NE'],
      ['NH', 'NH'],
      ['NJ', 'NJ'],
      ['NM', 'NM'],
      ['NV', 'NV'],
      ['NY', 'NY'],
      ['OH', 'OH'],
      ['OK', 'OK'],
      ['OR', 'OR'],
      ['PA', 'PA'],
      ['RI', 'RI'],
      ['SC', 'SC'],
      ['SD', 'SD'],
      ['TN', 'TN'],
      ['TX', 'TX'],
      ['UT', 'UT'],
      ['VA', 'VA'],
      ['VT', 'VT'],
      ['WA', 'WA'],
      ['WI', 'WI'],
      ['WV', 'WV'],
      ['WY', 'WY']
    ]
  end
end
