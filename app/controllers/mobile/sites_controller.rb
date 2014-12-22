class Mobile::SitesController < SitesController
  include Concerns::CheckApiDocs
  include Api::JsonHelper

  skip_before_filter  :verify_authenticity_token
  def new
    render layout: 'mobile'
  end

  def show
    respond_to do |format|
      format.json { render json: Site.find(params[:id]) }
    end
  end

  def create
    # site_params = JSON.parse params[:site]
    site_params = {}
    site_params[:name] = params[:name]
    site_params[:lng] = params[:lng]
    site_params[:lat] = params[:lat]
    if params[:properties]
      site_params[:properties] = params[:properties]
      site_params[:properties] = fix_timezone_on_date_properties(site_params[:properties])
      site_params[:properties] = self.store_image_file(site_params[:properties])
      site_params[:properties] = fix_value_on_yesNo_properties(site_params[:properties])
    end
    site = collection.sites.create(site_params.merge(user: current_user))
    if site.valid?
      Site::UploadUtils.uploadFile(params[:fileUpload])
      current_user.site_count += 1
      current_user.update_successful_outcome_status
      current_user.save!(:validate => false)
      render json: {site: site}, :status => 201
    else
      errors = []
      site.errors.messages[:properties].each do |error|
        error.each do |key, value|
          errors.push(value)
        end
      end
      render json: errors, :status => 500
    end
  end

  def update
    # site_params = JSON.parse params[:site]
    site_params = {}
    site_params[:name] = params[:name]
    site_params[:lng] = params[:lng]
    site_params[:lat] = params[:lat]
    if params[:properties]
      site_params[:properties] = params[:properties]
      site_params[:properties] = fix_timezone_on_date_properties(site_params[:properties])
      site_params[:properties] = self.store_image_file(site_params[:properties])
      site_params[:properties] = fix_value_on_yesNo_properties(site_params[:properties])     
    end
    if collection.sites.find(params[:id]).update_attributes!(site_params.merge(user: current_user))
      Site::UploadUtils.uploadFile(params[:fileUpload])
      current_user.site_count += 1
      current_user.update_successful_outcome_status
      current_user.save!(:validate => false)
      render json: {site: site}, :status => 201
    else
      errors = []
      site.errors.messages[:properties].each do |error|
        error.each do |key, value|
          errors.push(value)
        end
      end
      render json: errors, :status => 500
    end
  end

  def create_offline_site
    begin     
      # site_params = JSON.parse params[:site]
      site_params = {}
      site_params[:name] = params[:name]
      site_params[:lng] = params[:lng]
      site_params[:lat] = params[:lat]
      if params[:properties]
        site_params[:properties] = params[:properties]
        site_params[:properties] = fix_timezone_on_date_properties(site_params[:properties])
        site_params[:properties] = self.store_offline_image_file(site_params[:properties])
        site_params[:properties] = fix_value_on_yesNo_properties(site_params[:properties])        
      end
      site = collection.sites.create(site_params.merge(user: current_user))
      if site.valid?
        Site::UploadUtils.uploadFile(params[:fileUpload])
        current_user.site_count += 1
        current_user.update_successful_outcome_status
        current_user.save!(:validate => false)
        render json: {site: site, status: 201}
      end
    rescue => ex
      render json: {message: ex.message, status: 500 }
    end
  end

  def update_offline_site
    begin     
      # site_params = JSON.parse params[:site]
      site_params = {}
      site_params[:name] = params[:name]
      site_params[:lng] = params[:lng]
      site_params[:lat] = params[:lat]
      if params[:properties]
        site_params[:properties] = params[:properties]
        site_params[:properties] = fix_timezone_on_date_properties(site_params[:properties])
        site_params[:properties] = self.store_offline_image_file(site_params[:properties])
        site_params[:properties] = fix_value_on_yesNo_properties(site_params[:properties])        
      end
      if collection.sites.find(params[:id]).update_attributes!(site_params.merge(user: current_user))
        Site::UploadUtils.uploadFile(params[:fileUpload])
        current_user.site_count += 1
        current_user.update_successful_outcome_status
        current_user.save!(:validate => false)
        render json: {site: site, status: 201}
      end
    rescue => ex
      render json: {message: ex.message, status: 500 }
    end
  end

  def store_image_file(properties)
    properties.each do |key, value|
      if Field.find_by_id(key.to_i) and Field.find_by_id(key.to_i).kind == "photo" and properties[key].class != String
        if value and value != ""
          file_name = "#{key}#{DateTime.now.to_i}#{properties[key].original_filename}"
          Site::UploadUtils.uploadSingleFile(file_name, properties[key].read.to_s)
          properties[key] = file_name
        end
      end
    end
    properties
  end

  def store_offline_image_file(properties)
    properties.each do |key, value|
      if Field.find_by_id(key.to_i) and Field.find_by_id(key.to_i).kind == "photo" and properties[key].class != String
        if value and value != ""
          file_name = "#{key}#{DateTime.now.to_i}.jpg"
          # File.open("public/photo_field/#{file_name}", 'w') {|f| f.write(Base64.decode64(value)) }
          Site::UploadUtils.uploadSingleFile(file_name, Base64.decode64(value[(value.index(",")+1)..value.size]))
          properties[key] = file_name
        end
      end
    end
    properties
  end

  def fix_timezone_on_date_properties(properties)
    properties.each do |key, value|
      if Field.find_by_id(key.to_i) and Field.find_by_id(key.to_i).kind == "date"   
        unless(value.strip == "")
          properties[key] = value + "T00:00:00Z"
        end 
      end
    end
    properties
  end

  def fix_value_on_yesNo_properties(properties)
    properties.each do |key,value|
      if value == "on" #fix value for yes_no field
        properties[key] = true
        break
      end
    end
    properties
  end

end
