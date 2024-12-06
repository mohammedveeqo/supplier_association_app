class AddSkuCodeToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :sku_code, :string
  end
end
