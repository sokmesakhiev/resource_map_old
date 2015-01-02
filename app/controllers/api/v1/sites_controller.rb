module Api::V1
  class SitesController < ApplicationController
    include Concerns::CheckApiDocs
    include Api::JsonHelper

    before_filter :authenticate_api_user!
    skip_before_filter  :verify_authenticity_token
    expose(:site) { Site.find(params[:site_id] || params[:id]) }

    def index
      builder = Collection.filter_sites(params)
      sites_size = builder.size
      sites_by_page  = Collection.filter_page(params[:limit], params[:offset], builder)
      render :json => {:sites => sites_by_page, :total => sites_size}
    end

    def show
      search = new_search

      search.id(site.id)
      @result = search.api_results[0]

      respond_to do |format|
        format.rss
        format.json { render json: site_item_json(@result) }
      end
    end

    def update
      site.attributes = sanitized_site_params.merge(user: current_user)
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

    def create
      site = collection.sites.build sanitized_site_params.merge(user: current_user)
      if site.save
        current_user.site_count += 1
        current_user.update_successful_outcome_status
        current_user.save!(:validate => false)

        render json: site, status: :created
      else
        render json: site.errors.messages, status: :unprocessable_entity
      end
    end

    private
    def sanitized_site_params
      parameters = params[:site]
      fields = collection.writable_fields_for(current_user).index_by &:es_code
      site_properties = parameters.delete("properties") || {}
      files = parameters.delete("files") || {}

      decoded_properties = {}
      site_properties.each_pair do |es_code, value|
        value = [ value, files[value] ] if fields[es_code].kind_of? Field::PhotoField
        decoded_properties[es_code] = fields[es_code].decode_from_ui(value) if fields[es_code]
      end

      parameters["properties"] = decoded_properties
      parameters
    end
  end
end