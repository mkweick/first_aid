class CreateCustomer < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.integer   :user_id,     null: false
      t.datetime  :order_date,  null: false, default: Time.now
      t.string    :cust_num,    null: false
      t.string    :ship_to_num
      t.string    :po_num,      null: false, default: "FIRST AID"
      t.string    :cc_sq_num
      t.string    :cc_last_four
      t.string    :cust_name,   null: false
      t.string    :cust_line1
      t.string    :cust_line2
      t.string    :cust_city
      t.string    :cust_state
      t.string    :cust_zip
      t.timestamps              null: false
    end
  end
end
