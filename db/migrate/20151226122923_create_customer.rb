class CreateCustomer < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.integer :cust_num, null: false
      t.string :cust_name, null: false
      t.string :cust_line1
      t.string :cust_line2
      t.string :cust_city
      t.string :cust_state
      t.string :cust_zip
      t.integer :user_id, null: false
      t.timestamps null: false
    end
  end
end
