class Site < ActiveRecord::Base
  include Activity::AwareConcern
  include Site::ActivityConcern
  include Site::CleanupConcern
  include Site::GeomConcern
  include Site::PrefixConcern
  include Site::TireConcern
  include HistoryConcern

  belongs_to :collection
  validates_presence_of :name

  serialize :properties, Hash
  validate :valid_properties
  after_validation :standardize_properties
  before_validation :assign_default_values, :on => :create

  attr_accessor :from_import_wizard

  def history_concern_foreign_key
    self.class.name.foreign_key
  end

  def extended_properties
    @extended_properties ||= Hash.new
  end

  def update_properties(site, user, props)
    props.each do |p|
      field = Field.where(:collection_id => site.collection.id, :code => p.values[0]).first
      site.properties[field.id.to_s] = p.values[1]
    end
    site.save!
  end

  def human_properties
    fields = collection.fields.index_by(&:es_code)

    props = {}
    properties.each do |key, value|
      field = fields[key]
      if field
        props[field.name] = field.human_value value
      else
        props[key] = value
      end
    end
    props
  end

  def self.get_id_and_name sites
    sites = Site.select("id, name").find(sites)
    sites_with_id_and_name = []
    sites.each do |site|
      site_with_id_and_name = {
        "id" => site.id,
        "name" => site.name
      }
      sites_with_id_and_name.push site_with_id_and_name
    end
    sites_with_id_and_name
  end

  def self.create_or_update_from_hash! hash
    site = Site.where(:id => hash["site_id"]).first_or_initialize
    site.prepare_attributes_from_hash!(hash)
    site.save ? site : nil
  end

  def prepare_attributes_from_hash!(hash)
    self.collection_id = hash["collection_id"]
    self.name = hash["name"]
    self.lat = hash["lat"]
    self.lng = hash["lng"]
    self.user = hash["current_user"]
    properties = {}
    hash["existing_fields"].each_value do |field|
      properties[field["field_id"].to_s] = field["value"]
    end
    self.properties = properties
  end

  private

  def standardize_properties
    fields = collection.fields.index_by(&:es_code)

    standardized_properties = {}
    properties.each do |es_code, value|
      field = fields[es_code]
      if field
        standardized_properties[es_code] = field.standadrize(value)
      end
    end
    self.properties = standardized_properties
  end

  def assign_default_values
    fields = collection.fields.index_by(&:es_code)

    fields.each do |es_code, field|
      if properties[field.es_code].blank?
        value = field.default_value_for_create(collection)
        properties[field.es_code] = value if value
      end
    end   
  end

  def valid_properties
    fields = collection.fields.index_by(&:es_code)
    fields_mandatory = collection.fields.find_all_by_is_mandatory(true)
    properties.each do |es_code, value|
      field = fields[es_code]
      if field
        begin
          field.valid_value?(value, self)
        rescue => ex
          errors.add(:properties, {field.es_code => ex.message})
        end

        fields_mandatory.each do |f|
          if f.id.to_s == es_code.to_s
            fields_mandatory.delete f
          end
        end
      end
    end
    fields_mandatory.each do |f|
      errors.add(:properties, {f.id.to_s => "#{f.code} is required."})
    end

  end
end
