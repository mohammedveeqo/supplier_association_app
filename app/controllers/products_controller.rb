class ProductsController < ApplicationController
    require 'csv'
  
    def index
      @products = Product.all
      @csv_data ||= [] # Retain @csv_data if already initialized
  
      respond_to do |format|
        format.html # Render normal HTML
        format.turbo_stream # Support Turbo Streams explicitly
      end
    end
  
    def import
      if params[:file].present?
        csv_file = params[:file]
        @csv_data = []
  
        # Parse the CSV file
        CSV.foreach(csv_file.path, headers: true) do |row|
          base_data = {
            "sku_code" => row["sku_code"],
            "product_title" => row["product_title"]
          }
          @csv_data += parse_supplier_data(row).map { |supplier| base_data.merge(supplier) }
        end
  
        # Respond with the correct format to handle Turbo Streams and HTML
        respond_to do |format|
          format.turbo_stream { render :index } # Use `index.turbo_stream.erb` for Turbo Streams
          format.html { render :index } # Render `index.html.erb` for normal HTML
        end
      else
        redirect_to products_path, alert: "Please upload a CSV file."
      end
    rescue StandardError => e
      redirect_to products_path, alert: "Error processing CSV: #{e.message}"
    end
  
    def bulk_update
      params[:supplier_cost].each do |sku, supplier_data|
        product = Product.find_by(sku: sku)
  
        unless product
          Rails.logger.error "Product with SKU #{sku} not found."
          next
        end
  
        supplier_data.each do |supplier_id, cost|
          product.update_supplier_data(
            supplier_id,
            cost,
            params[:supplier_ref][sku][supplier_id]
          )
        end
      end
  
      redirect_to products_path, notice: "Supplier associations updated successfully."
    rescue StandardError => e
      redirect_to products_path, alert: "Error updating supplier associations: #{e.message}"
    end
  
    private
  
    def parse_supplier_data(row)
        supplier_data = []
        supplier_columns = row.headers.select { |col| col.match?(/supplier_\d+_/) }
        supplier_ids = supplier_columns.map { |col| col[/supplier_(\d+)_/, 1] }.uniq
      
        supplier_ids.each do |supplier_id|
          # Extract data for each supplier dynamically
          supplier_data << {
            "supplier_id" => supplier_id,
            "supplier_name" => row["supplier_#{supplier_id}_name"],
            "supplier_cost" => row["supplier_#{supplier_id}_cost"],
            "supplier_ref" => row["supplier_#{supplier_id}_ref"].presence || row["sku_code"]
          }
        end
      
        supplier_data
      end
      
  end
  