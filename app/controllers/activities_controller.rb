class ActivitiesController < ApplicationController

  expose(:collections) { 
    if current_user && !current_user.is_guest
      # public collections are accesible by all users
      # here we only need the ones in which current_user is a member
      current_user.collections.reject{|c| c.id.nil?}
    else
      Collection.accessible_by(current_ability)
    end 
  }

  def index
    respond_to do |format|
      format.html
      format.json do
        acts = Activity.order('id desc').includes(:collection, :site, :user)
        acts = acts.limit(25)
        acts = acts.where('id < ?', params[:before_id]) if params[:before_id]

        if params[:collection_ids]
          params[:collection_ids].each_with_index do |c_id, key|
            if c_id == 'null'
              params[:collection_ids][key] = nil
              break
            end
          end

          acts = acts.where("collection_id in (?) or user_id = ?", params[:collection_ids], current_user.id)
          acts = acts.where(collection_id: params[:collection_ids])

        else
          acts = acts.where("collection_id IN (?) or user_id = ?", current_user.memberships.pluck(:collection_id), current_user.id)

        end

        if params[:kinds]
          acts = acts.where("CONCAT(item_type, ',', action) IN (?)", params[:kinds])
        end

        activities_json = acts.map do |activity|
          {
            id: activity.id,
            collection: activity.collection_name,
            user: activity.user_email,
            log: activity.log,
            created_at: activity.created_at
          }
        end
        render json: activities_json
      end
    end
  end
  
  def download
    filename = 'download-history.csv'
    full_path = "#{Rails.root}/tmp/" + filename
    
    Activity.to_csv_file(params[:collection], full_path)
    file = File.open(full_path, "rb")
    contents = file.read
    send_data contents, :type => "text/csv" , :filename => filename
  end
  
  
end