module Collection::CsvConcern
  extend ActiveSupport::Concern
  # include Rails.application.routes.url_helpers
  def csv_template
    CSV.generate do |csv|
      csv << csv_header
      csv << [1, "Site 1", 1.234, 5.678]
      csv << [2, "Site 2", 3.456, 4.567]
    end
  end

  # def to_csv(elastic_search_api_results = new_search.unlimited.api_results, current_user)
  #   layers = self.layers.all
  #   fields = []
  #   hierarchy_fields = {}
  #   layers.each do |layer|
  #     allFields = layer.fields
  #     allFields.each do |field|
  #       fields.push(field)
  #     end
  #   end

  #   CSV.generate do |csv|
  #     header = ['resmap-id', 'name', 'lat', 'long']
  #     fields.each { |field| header << field.code }

  #     header << 'last updated'
  #     csv << header

  #     elastic_search_api_results.each do |result|
  #       source = result['_source']

  #       row = [source['id'], source['name'], source['location'].try(:[], 'lat'), source['location'].try(:[], 'lon')]
  #       fields.each do |field|
  #         if field.kind == 'yes_no'
  #           row << (Field.yes?(source['properties'][field.code]) ? 'yes' : 'no')
  #         elsif field.kind == 'photo'
  #           row << "#{Settings.host}/photo_field/#{source['properties'][field.code]}"
  #         else
  #           row << Array(source['properties'][field.code]).join(", ")
  #         end
  #       end
  #       if current_user
  #         updated_at = Site.iso_string_to_rfc822_with_timezone(source['updated_at'], current_user.time_zone)
  #       else
  #         updated_at = Site.iso_string_to_rfc822(source['updated_at'])
  #       end
  #       # row << Site.iso_string_to_rfc822(source['updated_at'])
  #       row << updated_at
  #       csv << row
  #     end
  #   end
  # end

  def to_csv(elastic_search_api_results, user, snapshot_id = nil, options = {})
    fields = self.visible_fields_for(user, {snapshot_id: snapshot_id})
    fields.each(&:cache_for_read)

    CSV.generate do |csv|
      header = ['resmap-id', 'name', 'lat', 'long']
      fields.each do |field|
        field.csv_headers.each do |column_header|
          header << column_header
        end
      end
      header << 'last updated'
      csv << header

      elastic_search_api_results.each do |result|
        source = result['_source']

        row = [source['id'], source['name'], source['location'].try(:[], 'lat'), source['location'].try(:[], 'lon')]
        fields.each do |field|
          field.csv_values(source['properties'][field.code], options[:human]).each do | value |
            if field.kind == 'yes_no'
              row << (Field.yes?(source['properties'][field.code]) ? 'yes' : 'no')
            elsif field.kind == 'photo'
              row << "#{Settings.host}/photo_field/#{source['properties'][field.code]}"
            else
              row << Array(source['properties'][field.code]).join(", ")
            end
          end
        end
        row << Site.iso_string_to_rfc822(source['updated_at'])
        csv << row
      end
    end
  end

  def location_csv(locations)
    CSV.generate do |csv|
      locations.each do |location|
        csv << [location["code"], location["name"], location["latitude"], location["longitude"]]
      end
    end      
  end

  def sample_csv(user = nil)
    fields = self.fields.all

    CSV.generate do |csv|
      header = ['name', 'lat', 'long']
      writable_fields = writable_fields_for(user)
      writable_fields.each { |field| header << field.code }
      csv << header
      row = ['Paris', 48.86, 2.35]
      writable_fields.each do |field|
        row << Array(field.sample_value user).join(", ")
      end
      csv << row
    end
  end

  def import_csv(user, string_or_io)
    Collection.transaction do
      csv = CSV.new string_or_io, return_headers: false

      new_sites = []
      csv.each do |row|
        next unless row[0].present? && row[0] != 'resmap-id'

        site = sites.new name: row[1].strip
        site.mute_activities = true
        site.lat = row[2].strip if row[2].present?
        site.lng = row[3].strip if row[3].present?
        new_sites << site
      end

      new_sites.each &:save!

      Activity.create! item_type: 'collection', action: 'csv_imported', collection_id: id, user_id: user.id, 'data' => {'sites' => new_sites.length}
    end
  end

  def decode_hierarchy_csv(string)

    csv = CSV.parse(string)

    # First read all items into a hash
    # And validate it's content
    items = validate_format(csv)

    # Add to parents
    items.each do |order, item|
      if item[:parent].present? && !item[:error].present?
        parent_candidates = items.select{|key, hash| hash[:id] == item[:parent]}

        if parent_candidates.any?
          parent = parent_candidates.first[1]
        end

        if parent
          parent[:sub] ||= []
          parent[:sub] << item
        end
      end
    end

    p 'items : ', items


    # Remove those that have parents, and at the same time delete their parent key
    items = items.reject do |order, item|
      if item[:parent] && !item[:error].present?
        item.delete :parent
        true
      else
        false
      end
    end


    items.values

    rescue Exception => ex
      return [{error: ex.message}]

  end

  def decode_location_csv(string)
    csv = CSV.parse(string)

    items = validate_format_location(csv)

    locations = []
    items.each do |item|
      locations.push item[1]
    end
    
    locations
    
    rescue Exception => ex
      return [{error: ex.message}]
  end

  def validate_format_location(csv)
    i = 0
    items = {}
    csv.each do |row|
      item = {}
      if row[0] == 'Code'
        next
      else
        i = i+1
        item[:order] = i

        if row.length != 4
          item[:error] = "Wrong format."
          item[:error_description] = "Invalid column number"
        else

          #Check unique name
          name = row[1].strip
          # if items.any?{|item| item.second[:name] == name}
          #   item[:error] = "Invalid name."
          #   item[:error_description] = "location name should be unique"
          #   error = true
          # end
          
          #Check unique id
          code = row[0].strip
          # if items.any?{|item| item.second[:code] == code}
          #   item[:error] = "Invalid code."
          #   item[:error_description] = "location code should be unique"
          #   error = true
          # end

          # if !error
            item[:code] = code
            item[:name] = name
            item[:latitude] = row[2].strip
            item[:longitude] = row[3].strip
          # end
        end

        items[item[:order]] = item
      end
    end
    items
  end

  def validate_format(csv)
    i = 0
    items = {}
    csv.each do |row|
      item = {}
      if row[0] == 'ID'
        next
      else
        i = i+1
        item[:order] = i

        if row.length != 3
          item[:error] = "Wrong format."
          item[:error_description] = "Invalid column number"
        else

          #Check unique name
          name = row[2].strip
          if items.any?{|item| item.second[:name] == name}
            item[:error] = "Invalid name."
            item[:error_description] = "Hierarchy name should be unique"
            error = true
          end
          
          #Check unique id
          id = row[0].strip
          if items.any?{|item| item.second[:id] == id}
            item[:error] = "Invalid id."
            item[:error_description] = "Hierarchy id should be unique"
            error = true
          end

          #Check parent id exists
          parent_id = row[1]
          if(parent_id.present? && !csv.any?{|csv_row| csv_row[0].strip == parent_id.strip})
            item[:error] = "Invalid parent value."
            item[:error_description] = "ParentID should match one of the Hierarchy ids"
            error = true
          end

          if !error
            item[:id] = id
            item[:parent] = row[1].strip if row[1].present?
            item[:name] = name
          end
        end

        items[item[:order]] = item
      end
    end
    items
  end

  private

  def csv_header
    ["Site ID", "Name", "Lat", "Lng"]
  end
end
