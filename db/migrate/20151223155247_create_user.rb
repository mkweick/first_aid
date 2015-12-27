class CreateUser < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :username, null: false
      t.string :password_digest, null: false
      t.integer :whs_id, null: false
      t.boolean :admin, default: false, null: false
      t.timestamps null: false
    end
  end
end
