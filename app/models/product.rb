class Product < ApplicationRecord
  # Assuming there's a relationship with a Supplier model
  has_many :supplier_products
  has_many :suppliers, through: :supplier_products

  def update_supplier_data(supplier_id, cost, reference)
    supplier_product = supplier_products.find_or_initialize_by(supplier_id: supplier_id)
    supplier_product.update(cost: cost, reference: reference)
  end
end
