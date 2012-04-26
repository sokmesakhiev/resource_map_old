class SitesController < ApplicationController
  before_filter :authenticate_user!

  expose(:sites)
  expose(:site)

  def index
    render json: collection.root_sites.offset(params[:offset]).limit(params[:limit])
  end

  def show
    render json: site
  end

  def create
    site = collection.sites.create(params[:site].merge(user: current_user))
    render json: site
  end

  def update
    site.user = current_user
    site.properties_will_change!
    site.update_attributes! params[:site]
    render json: site
  end

  def update_property
    return head :forbidden unless current_user.can_write_field? site.collection, params[:code]

    site.user = current_user
    site.properties_will_change!
    site.properties[params[:code]] = params[:value]
    site.save!
    render json: site
  end

  def root_sites
    render json: site.sites.where(parent_id: site.id).offset(params[:offset]).limit(params[:limit])
  end

  def search
    zoom = params[:z].to_i

    search = MapSearch.new params[:collection_ids]
    search.zoom = zoom
    search.bounds = params if zoom >= 2
    search.exclude_id params[:exclude_id].to_i if params[:exclude_id].present?
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search].present?
    search.where params.except(:action, :controller, :format, :n, :s, :e, :w, :z, :collection_ids, :exclude_id, :updated_since, :search)
    render json: search.results
  end

  def destroy
    site.user = current_user
    site.destroy
    render json: site
  end
end
