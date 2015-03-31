class SitesController < ApplicationController
  before_filter :setup_guest_user, :if => Proc.new { collection && collection.public }
  before_filter :authenticate_user!, :except => [:index, :search, :search_alert_site], :unless => Proc.new { collection && collection.public }

  authorize_resource :only => [:index, :search, :search_alert_site], :decent_exposure => true

  expose(:sites) {if !current_user_snapshot.at_present? && collection then collection.site_histories.at_date(current_user_snapshot.snapshot.date) else collection.sites end}
  expose(:site) { Site.find(params[:site_id] || params[:id]) }

  def index
    search = new_search

    search.name_start_with params[:name] if params[:name].present?
    search.alerted_search params[:_alert] if params[:_alert] == "true"
    search.offset params[:offset]
    search.limit params[:limit]

    render json: search.ui_results.map { |x| x['_source'] }
  end

  def show
    search = new_search

    search.id params[:id]
    # If site does not exists, return empty objects
    result = search.ui_results.first['_source'] rescue {}
    render json: result
  end

  def create
    site_params = JSON.parse params[:site]
    ui_attributes = prepare_from_ui(site_params)
    site = collection.sites.new(ui_attributes.merge(user: current_user))
    if site.valid?
      site.save!
      current_user.site_count += 1
      current_user.update_successful_outcome_status
      current_user.save!(:validate => false)
      render json: site, :layout => false
    else
      render json: site.errors.messages, status: :unprocessable_entity, :layout => false
    end
  end

  def update
    site_params = JSON.parse params[:site]
    site.user = current_user
    site.properties_will_change!
    site.attributes = prepare_from_ui(site_params)
    if site.valid?
      site.save!
      if params[:photosToRemove]
        Site::UploadUtils.purgePhotos(params[:photosToRemove])
      end
      render json: site, :layout => false
    else
      render json: site.errors.messages, status: :unprocessable_entity, :layout => false
    end
  end

  def update_property
    field = site.collection.fields.where_es_code_is params[:es_code]
    if not site.collection.site_ids_permission(current_user).include? site.id
      return head :forbidden unless current_user.can_write_field? field, site.collection, params[:es_code]
    end

    site.user = current_user
    site.properties_will_change!

    site.properties[params[:es_code]] = field.decode_from_ui(params[:value])
    if site.valid?
      site.save!
      render json: site, :status => 200, :layout => false
    else
      error_message = site.errors[:properties][0][params[:es_code]]
      render json: {:error_message => error_message}, status: :unprocessable_entity, :layout => false
    end
  end

  def search
    zoom = params[:z].to_i

    search = MapSearch.new params[:collection_ids], user: current_user

    search.zoom = zoom
    search.bounds = params if zoom >= 2
    search.exclude_id params[:exclude_id].to_i if params[:exclude_id].present?
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search].present?
    search.alerted_search params[:_alert] if params[:_alert].present?
    search.location_missing if params[:location_missing].present?
    if params[:selected_hierarchies].present?
      search.selected_hierarchy params[:hierarchy_code], params[:selected_hierarchies]
    end
    search.where params.except(:action, :controller, :format, :n, :s, :e, :w, :z, :collection_ids, :exclude_id, :updated_since, :search, :location_missing, :hierarchy_code, :selected_hierarchies, :_alert)

    search.apply_queries
    render json: search.results
  end

  def search_alert_site
    zoom = params[:z].to_i

    search = MapSearch.new params[:collection_ids], user: current_user

    search.zoom = zoom
    search.bounds = params if zoom >= 2
    search.exclude_id params[:exclude_id].to_i if params[:exclude_id].present?
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search].present?
    search.alerted_search params[:_alert] if params[:_alert].present?
    search.location_missing if params[:location_missing].present?
    if params[:selected_hierarchies].present?
      search.selected_hierarchy params[:hierarchy_code], params[:selected_hierarchies]
    end
    search.where params.except(:action, :controller, :format, :n, :s, :e, :w, :z, :collection_ids, :exclude_id, :updated_since, :search, :location_missing, :hierarchy_code, :selected_hierarchies, :_alert)

    search.apply_queries
    render json: search.sites_json    
  end

  def destroy
    site.user = current_user
    Site::UploadUtils.purgeUploadedPhotos(site)
    site.destroy
    render json: site
  end

  def visible_layers_for
    layers = []
    if site.collection.site_ids_permission(current_user).include? site.id
      target_fields = fields.includes(:layer).all
      layers = target_fields.map(&:layer).uniq.map do |layer|
        {
          id: layer.id,
          name: layer.name,
          ord: layer.ord,
        }
      end
      if site.collection.site_ids_write_permission(current_user).include? site.id
        layers.each do |layer|
          layer[:fields] = target_fields.select { |field| field.layer_id == layer[:id] }
          layer[:fields].map! do |field|
            {
              id: field.es_code,
              name: field.name,
              code: field.code,
              kind: field.kind,
              config: field.config,
              ord: field.ord,
              writeable: true
            }
          end
        end
      elsif site.collection.site_ids_read_permission(current_user).include? site.id
        layers.each do |layer|
          layer[:fields] = target_fields.select { |field| field.layer_id == layer[:id] }
          layer[:fields].map! do |field|
            {
              id: field.es_code,
              name: field.name,
              code: field.code,
              kind: field.kind,
              config: field.config,
              ord: field.ord,
              writeable: false
            }
          end
        end
      end
      layers.sort! { |x, y| x[:ord] <=> y[:ord] }
    else
      layers = site.collection.visible_layers_for(current_user)
    end
    render json: layers
  end

  private

  def prepare_from_ui(parameters)
    fields = collection.fields.index_by(&:es_code)
    decoded_properties = {}
    site_properties = parameters.delete("properties") || {}
    files = params[:fileUpload] || {}

    site_properties.each_pair do |es_code, value|
      value = [ value, files[value] ] if fields[es_code].kind == 'photo'
      decoded_properties[es_code] = fields[es_code].decode_from_ui(value)
    end

    parameters["properties"] = decoded_properties unless decoded_properties.blank?
    parameters
  end
end
