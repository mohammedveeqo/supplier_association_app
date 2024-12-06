class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :sku
      t.string :name
      t.string :supplier
      t.decimal :cost_price, precision: 10, scale: 2

      t.timestamps
    end
  end
end
