class CollectionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, :only => :destroy
  before_filter :breadcrumb

  def index
    respond_to do |format|
      format.html
      format.json { render json: collections }
    end
  end

  def new
    add_breadcrumb "Create new collection", nil
  end

  def create
    if current_user.create_collection collection
      redirect_to collections_path, notice: "Collection #{collection.name} created"
    else
      render :new
    end
  end

  def update
    if collection.update_attributes params[:collection]
      redirect_to collection_settings_path(collection), notice: "Collection #{collection.name} updated"
    else
      render :settings
    end
  end

  def show
    respond_to do |format|
      format.html { add_breadcrumb collection.name, collection_path(collection) }
      format.json { render json: collection }
    end
  end

  def members
    add_breadcrumb collection.name, collection_path(collection)
    add_breadcrumb "Members", collection_members_path(collection)
  end

  def thresholds
    add_breadcrumb collection.name, collection_path(collection)
    add_breadcrumb "Thresholds", collection_thresholds_path(collection)
  end

  def reminders
    add_breadcrumb collection.name, collection_path(collection)
    add_breadcrumb "Reminders", collection_reminders_path(collection)
  end

  def settings
    add_breadcrumb collection.name, collection_path(collection)
    add_breadcrumb "Settings", collection_settings_path(collection)
  end

  def destroy
    collection.destroy

    redirect_to collections_path, notice: "Collection #{collection.name} deleted"
  end

  def download_as_csv
    send_data collection.export_csv, type: 'text/csv', filename: "#{collection.name}_sites.csv"
  end

  def csv_template
    send_data collection.csv_template, type: 'text/csv', filename: "collection_sites_template.csv"
  end

  def upload_csv
    collection.import_csv!(params[:file].read)
    redirect_to collections_path
  end

  def max_value_of_property
    render json: collection.max_value_of_property(params[:property])
  end

  def import_wizard_upload_csv
    ImportWizard.import current_user, collection, params[:file]
    redirect_to collection_import_wizard_adjustments_path(collection)
  rescue => ex
    redirect_to collection_import_wizard_path(collection), :notice => "The file was not a valid CSV file"
  end

  def import_wizard_adjustments
    @sample = ImportWizard.sample(current_user, collection)
  end

  private

  def breadcrumb
    @show_breadcrumb = true
    add_breadcrumb "Collections", collections_path
  end
end
