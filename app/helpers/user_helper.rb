require 'odbc'

module UserHelper

  def user_warehouses
    as400 = ODBC.connect('first_aid_f')
    sql_warehouses = "SELECT SUBSTRING(ccctlk,6,7) FROM orctl
                      WHERE ccctlk LIKE 'WHSNU%'"
    warehouses = as400.run(sql_warehouses).fetch_all.flatten
    as400.commit
    as400.disconnect
    warehouses
  end
end
