class Product < ApplicationRecord
  validates :sku, presence: true
  validates :name, presence: true
  validates :supplier, allow_blank: true, format: { with: /\A[\w\s]+\z/, message: "only allows letters and numbers" }
  validates :cost_price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
end