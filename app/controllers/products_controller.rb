class ProductsController < ApplicationController
    require 'csv'
  
    def index
      @products = Product.all
      @csv_data ||= [] # Ensure @csv_data is initialized
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
          @csv_data << {
            "sku_code" => base_data["sku_code"],
            "product_title" => base_data["product_title"],
            "suppliers" => parse_supplier_data(row)
          }
        end
  
        # Respond to Turbo Streams or HTML
        respond_to do |format|
          format.turbo_stream { render :index } # Renders `index.turbo_stream.erb`
          format.html { render :index }        # Renders `index.html.erb`
        end
      else
        # Handle missing file gracefully
        respond_to do |format|
          format.html { redirect_to products_path, alert: "Please upload a CSV file." }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("alert", partial: "shared/alert", locals: { message: "Please upload a CSV file." })
          end
        end
      end
    rescue StandardError => e
      # Handle errors
      respond_to do |format|
        format.html { redirect_to products_path, alert: "Error processing CSV: #{e.message}" }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("alert", partial: "shared/alert", locals: { message: "Error processing CSV: #{e.message}" })
        end
      end
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
      suppliers = []
      supplier_columns = row.headers.select { |col| col.match?(/supplier_\d+_/) }
      supplier_ids = supplier_columns.map { |col| col[/supplier_(\d+)_/, 1] }.uniq
  
      supplier_ids.each do |supplier_id|
        suppliers << {
          "supplier_id" => supplier_id,
          "supplier_name" => row["supplier_#{supplier_id}_name"],
          "supplier_cost" => row["supplier_#{supplier_id}_cost"],
          "supplier_ref" => row["supplier_#{supplier_id}_ref"].presence || row["sku_code"]
        }
      end
  
      suppliers
    end
  end
  