class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :customer_id, null: false
      t.string :building, null: false
      t.string :kit, null: false
      t.string :item_num, null: false
      t.string :item_desc, null: false
      t.integer :item_qty, null: false
      t.float :item_price, null: false
      t.string :item_price_type, null: false
      t.timestamps null: false
    end
  end
end
