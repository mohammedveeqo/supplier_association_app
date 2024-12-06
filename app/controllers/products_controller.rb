class ProductsController < ApplicationController
    require 'csv'
  
    def index
      @products = Product.all
    end
  
    def import
      if params[:file].present?
        csv_file = params[:file]
        valid_attributes = Product.attribute_names.map(&:to_sym)
  
        # Process each row of the CSV file
        CSV.foreach(csv_file.path, headers: true) do |row|
          # Filter only valid attributes from CSV
          product_data = row.to_h.symbolize_keys.slice(*valid_attributes)
  
          # Map CSV columns to the expected attributes
          product_data[:sku] = product_data.delete(:sku_code)
          product_data[:name] = product_data.delete(:product_title)
  
          begin
            # Create product record with filtered data
            Product.create!(product_data)
          rescue ActiveRecord::RecordInvalid => e
            # Log validation errors for the failed import
            logger.error "Product import failed: #{e.message}"
          rescue ActiveRecord::UnknownAttributeError => e
            # Log unknown attribute errors
            logger.error "Skipping row due to unknown attributes: #{e.message}"
          end
        end
  
        redirect_to products_path, notice: "Products imported successfully."
      else
        redirect_to products_path, alert: "No file uploaded."
      end
    rescue StandardError => e
      redirect_to products_path, alert: "Error during import: #{e.message}"
    end
  end
  