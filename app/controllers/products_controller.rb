class ProductsController < ApplicationController
  require 'csv'

  def index
    @csv_data = session[:csv_data] || []
    Rails.logger.info "Session Data at Index: #{@csv_data.inspect}" # Debug session data
  end

  def import
    if params[:file].present?
      csv_file = params[:file]
      @csv_data = []

      Rails.logger.info "CSV file uploaded: #{csv_file.original_filename}" # Log file name

      # Parse the CSV file
      CSV.foreach(csv_file.path, headers: true) do |row|
        Rails.logger.info "Processing row: #{row.to_h}" # Log each row being processed

        # Extract fixed product fields
        relevant_data = {
          "sku_code" => row["sku_code"],
          "product_id" => row["product_id"],
          "product_title" => row["product_title"],
          "sell_price" => row["sell_price"],
          "tax_rate" => row["tax_rate"],
          "suppliers" => parse_supplier_data(row)
        }
        @csv_data << relevant_data
      end

      session[:csv_data] = @csv_data
      Rails.logger.info "Final Session Data: #{session[:csv_data].inspect}" # Debug session data

      respond_to do |format|
        format.turbo_stream { render :import }
        format.html { redirect_to products_path, notice: "CSV uploaded and parsed successfully." }
      end
    else
      redirect_to products_path, alert: "Please upload a valid CSV file."
    end
  rescue StandardError => e
    Rails.logger.error "Error processing CSV: #{e.message}"
    redirect_to products_path, alert: "Error processing CSV: #{e.message}"
  end

  def bulk_update
    @csv_data = session[:csv_data] || []

    if params[:supplier_cost].present?
      @csv_data.each do |row|
        row["suppliers"].each do |supplier|
          supplier_id = supplier["supplier_id"]
          if params[:supplier_cost][row["sku_code"]] && params[:supplier_cost][row["sku_code"]][supplier_id]
            supplier["supplier_cost"] = params[:supplier_cost][row["sku_code"]][supplier_id]
          end
        end
      end

      session[:csv_data] = @csv_data
      redirect_to products_path, notice: "Supplier costs updated successfully."
    else
      redirect_to products_path, alert: "No updates provided."
    end
  end

  def export
    @csv_data = session[:csv_data] || []

    csv_data = CSV.generate(headers: true) do |csv|
      headers = ["sku_code", "product_id", "product_title", "sell_price", "tax_rate"]
      max_suppliers = @csv_data.map { |row| row["suppliers"].size }.max || 0

      (1..max_suppliers).each do |index|
        headers += [
          "supplier_#{index}_id",
          "supplier_#{index}_name",
          "supplier_#{index}_cost",
          "supplier_#{index}_ref"
        ]
      end
      csv << headers

      @csv_data.each do |row|
        base_row = [
          row["sku_code"],
          row["product_id"],
          row["product_title"],
          row["sell_price"],
          row["tax_rate"]
        ]

        supplier_data = []
        row["suppliers"].each do |supplier|
          supplier_data += [
            supplier["supplier_id"],
            supplier["supplier_name"],
            supplier["supplier_cost"],
            supplier["supplier_ref"]
          ]
        end

        remaining_slots = (max_suppliers - row["suppliers"].size) * 4
        supplier_data += Array.new(remaining_slots, nil)

        csv << base_row + supplier_data
      end
    end

    send_data csv_data, filename: "exported_supplier_data.csv", type: "text/csv"
  end

  def clear
    session[:csv_data] = nil
    redirect_to products_path, notice: "Data cleared. You can upload a new CSV."
  end

  private

  def parse_supplier_data(row)
    suppliers = []
    supplier_columns = row.headers.select { |col| col.match?(/supplier_\d+_/) }
    supplier_ids = supplier_columns.map { |col| col[/supplier_(\d+)_/, 1] }.uniq

    supplier_ids.each do |supplier_id|
      suppliers << {
        "supplier_id" => row["supplier_#{supplier_id}_id"],
        "supplier_name" => row["supplier_#{supplier_id}_name"],
        "supplier_cost" => row["supplier_#{supplier_id}_cost"],
        "supplier_ref" => row["supplier_#{supplier_id}_ref"]
      }
    end

    suppliers
  end
end
