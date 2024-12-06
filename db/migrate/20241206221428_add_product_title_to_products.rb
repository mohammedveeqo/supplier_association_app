class AddProductTitleToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :product_title, :string
  end
end
