class CreateCreditCards < ActiveRecord::Migration
  def change
    create_table :credit_cards do |t|
      t.integer :customer_id, null: false
      t.string  :cc_num, null: false
      t.string  :cc_exp_mth, null: false
      t.string  :cc_exp_year, null: false
      t.string  :cc_name
      t.string  :cc_line1
      t.string  :cc_city
      t.string  :cc_state
      t.string  :cc_zip
      t.timestamps null: false
    end
  end
end
