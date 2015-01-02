class ImportWizardsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :show_collection_breadcrumb
  before_filter :show_properties_breadcrumb
  before_filter :authenticate_collection_admin!, only: :logs

  expose(:import_job) { ImportJob.last_for current_user, collection }
  expose(:failed_import_jobs) { ImportJob.where(collection_id: collection.id).where(status: 'failed').order('id desc').page(params[:page]).per_page(10) }

  def index
    return redirect_to import_in_progress_collection_import_wizard_path(collection) if (import_job && (import_job.status_pending? || import_job.status_in_progress?))

    add_breadcrumb I18n.t('views.collections.tab.import_wizard'), collection_import_wizard_path(collection)
  end

  def upload_csv
    begin
      ImportWizard.import current_user, collection, params[:file].original_filename, params[:file].read
      redirect_to adjustments_collection_import_wizard_path(collection)
    rescue => ex
      redirect_to collection_import_wizard_path(collection), :alert => ex.message
    end
  end

  def guess_columns_spec
    render json: ImportWizard.guess_columns_spec(current_user, collection)
  end

  def adjustments
    add_breadcrumb I18n.t('views.collections.tab.import_wizard'), collection_import_wizard_path(collection)
  end

  def validate_sites_with_columns
    render json: ImportWizard.validate_sites_with_columns(current_user, collection, JSON.parse(params[:columns]))
  end

  def execute
    columns = params[:columns].values
    if columns.find { |x| x[:usage] == 'new_field' } and not current_user.admins? collection
      render text: I18n.t('views.import_wizards.cant_create_new_fields'), status: :unauthorized
    else
      ImportWizard.enqueue_job current_user, collection, params[:columns].values
      render json: :ok
    end
  end

  def import_in_progress
    redirect_to import_finished_collection_import_wizard_path(collection) if import_job.status_finished?

    add_breadcrumb I18n.t('views.collections.tab.import_wizard'), collection_import_wizard_path(collection)
  end

  def import_finished
    add_breadcrumb I18n.t('views.collections.tab.import_wizard'), collection_import_wizard_path(collection)
  end

  def import_failed
    add_breadcrumb I18n.t('views.collections.tab.import_wizard'), collection_import_wizard_path(collection)
  end

  def cancel_pending_jobs
    ImportWizard.cancel_pending_jobs(current_user, collection)
    flash[:notice] = I18n.t('views.import_wizards.import_canceled')
    redirect_to collection_import_wizard_path
  end

  def job_status
    render json: {:status => import_job.status}
  end

  def logs
    add_breadcrumb I18n.t('views.collections.tab.import_wizard'), collection_import_wizard_path(collection)
  end
end
