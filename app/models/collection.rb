class Collection < ActiveRecord::Base
  include Collection::CsvConcern
  include Collection::ShpConcern
  include Collection::GeomConcern
  include Collection::KmlConcern
  include Collection::TireConcern
  include Collection::PluginsConcern
  include Collection::ImportLayersSchemaConcern


  validates_presence_of :name

  has_many :memberships, :dependent => :destroy
  has_many :layer_memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :sites, dependent: :delete_all
  has_many :layers, order: 'ord', dependent: :destroy
  has_many :fields
  has_many :thresholds, dependent: :destroy
  has_many :reminders, dependent: :destroy
  has_many :share_channels, dependent: :destroy
  has_many :channels, :through => :share_channels
  has_many :activities, dependent: :destroy
  has_many :snapshots, dependent: :destroy
  has_many :user_snapshots, :through => :snapshots
  has_many :site_histories, dependent: :destroy
  has_many :layer_histories, dependent: :destroy
  has_many :field_histories, dependent: :destroy
  has_many :messages, dependent: :destroy
  OPERATOR = {">" => "gt", "<" => "lt", ">=" => "gte", "<=" => "lte", "=>" => "gte", "=<" => "lte", "=" => "eq"}

  attr_accessor :time_zone

  def max_value_of_property(es_code)
    search = new_tire_search
    search.sort { by es_code, 'desc' }
    search.size 2000
    results = search.perform.results
    results.first['_source']['properties'][es_code] rescue 0
  end

  def snapshot_for(user)
    user_snapshots.where(user_id: user.id).first.try(:snapshot)
  end

  def writable_fields_for(user)
    membership = user.membership_in self
    return [] unless membership

    target_fields = fields.includes(:layer)

    if membership.admin?
      target_fields = target_fields.all
    else
      lms = LayerMembership.where(user_id: user.id, collection_id: self.id).all.inject({}) do |hash, lm|
        hash[lm.layer_id] = lm
        hash
      end

      target_fields = target_fields.select {|f| lms[f.layer_id] && lms[f.layer_id].write}

    end
    target_fields
  end

  def site_ids_write_permission(user)
    site_ids, membership = [], user.membership_in(self)
    if membership
      write_sites_permission = membership.write_sites_permission
      site_ids.concat(write_sites_permission['some_sites'].map{ |site| site['id'].to_i}) if write_sites_permission
    end

    site_ids.uniq
  end

  def site_ids_read_permission(user)
    site_ids, membership = [], user.membership_in(self)
    if membership
      read_sites_permission = membership.read_sites_permission
      site_ids.concat(read_sites_permission['some_sites'].map{ |site| site['id'].to_i}) if read_sites_permission
    end

    site_ids.uniq
  end

  def site_ids_permission(user)
    site_ids, membership = [], user.membership_in(self)
    if membership
      read_sites_permission = membership.read_sites_permission
      write_sites_permission = membership.write_sites_permission

      site_ids.concat(read_sites_permission['some_sites'].map{ |site| site['id'].to_i}) if read_sites_permission
      site_ids.concat(write_sites_permission['some_sites'].map{ |site| site['id'].to_i}) if write_sites_permission
    end

    site_ids.uniq
  end

  def visible_fields_for(user, options, language = nil)
    if user.try(:is_guest)
      return fields.includes(:layer).all
    end

    membership = user.try :membership_in, self
    return [] unless membership
    if options[:snapshot_id]
      date = Snapshot.where(id: options[:snapshot_id]).first.date
      target_fields = field_histories.at_date(date).includes(:layer)
    else
      target_fields = fields.includes(:layer)
    end
    if membership.admin?
      target_fields = target_fields.all
    else
      lms = LayerMembership.where(user_id: user.id, collection_id: self.id).all.inject({}) do |hash, lm|
        hash[lm.layer_id] = lm
        hash
      end

      target_fields = target_fields.select { |f| lms[f.layer_id] && lms[f.layer_id].read }

    end
    target_fields
  end

  def visible_layers_for(user, options = {}, language = nil)
    target_fields = visible_fields_for(user, options, language)
    layers = target_fields.map(&:layer).uniq.map do |layer|
      {
        id: layer.id,
        name: layer.name,
        ord: layer.ord,
      }
    end

    membership = user.membership_in self
    if !user.is_guest && !membership.try(:admin?)
      lms = LayerMembership.where(user_id: user.id, collection_id: self.id).all.inject({}) do |hash, lm|
        hash[lm.layer_id] = lm
        hash
      end
    end

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
          is_mandatory: field.is_mandatory,
          is_enable_field_logic: field.is_enable_field_logic,
          # field_logic_value: field.field_logic_value,
          writeable: user.is_guest ? false : !lms || lms[field.layer_id].write
        }
      end
    end
    layers.sort! { |x, y| x[:ord] <=> y[:ord] }
    layers
  end

  # Returns the next ord value for a layer that is going to be created
  def next_layer_ord
    layer = layers.select('max(ord) as o').first
    layer ? layer['o'].to_i + 1 : 1
  end

  def delete_sites_and_activities
    ActiveRecord::Base.transaction do
      Activity.where(collection_id: id).delete_all
      Site.where(collection_id: id).delete_all
      recreate_index
    end
  end

  def thresholds_test(site)
    catch(:threshold) {
      thresholds.each do |threshold|
        threshold.test site.properties if threshold.is_all_site || threshold.sites.any? { |selected| selected["id"] == site.id }
      end
      nil
    }
  end

  def query_sites(option)
    operator = operator_parser option[:operator]
    field = Field.find_by_code option[:code]

    search = self.new_search
    search.use_codes_instead_of_es_codes

    search.send operator, field, option[:value]
    results = search.results
    response_prepare(option[:code], field.id, results)
  end

  def response_prepare(field_code, field_id, results)
    array_result = []
    results.each do |r|
      array_result.push "#{r["_source"]["name"]}=#{r["_source"]["properties"][field_id.to_s]}"
    end
    response_sms = (array_result.empty?)? "There is no site matched" : array_result.join(", ")
    result = "[\"#{field_code}\"] in #{response_sms}"
    result
  end

  def operator_parser(op)
    OPERATOR[op]
  end

  def active_gateway
    self.channels.each do |channel|
      return channel if channel.client_connected && channel.is_enable && !channel.share_channels.find_by_collection_id(id).nil?
    end
    nil
  end

  def get_user_owner
    memberships.find_by_admin(true).user
  end

  def get_gateway_under_user_owner
    get_user_owner.get_gateway
  end

  def register_gateways_under_user_owner(owner_user)
    self.channels = owner_user.channels.find_all_by_is_enable true
  end

  # Returns a dictionary of :code => :es_code of all the fields in the collection
  def es_codes_by_field_code
    self.fields.inject({}) do |dict, field|
      dict[field.code] = field.es_code
      dict
    end
  end

  def self.filter_sites params
    builder = Collection.find(params[:collection_id]).sites
    if !params[:from].blank? && !params[:to].blank?
      from = params[:from]
      to   = params[:to]
      builder = builder.where(['sites.created_at BETWEEN :from AND :to', :from => from, :to => to])
    elsif !params[:from].blank?
      from = params[:from]
      builder = builder.where(['sites.created_at >= :from', :from => from])
    elsif !params[:to].blank? 
      to = params[:to]
      builder = builder.where(['sites.created_at <= :to', :to => to])
    end
    builder 
  end

  def self.filter_page limit, offset, builder
    builder = builder.limit limit   if limit
    builder = builder.offset offset if offset
    builder.find(:all, :order => "sites.created_at DESC") 
  end

  def new_site_properties
    self.fields.each_with_object({}) do |field, hash|
      value = field.default_value_for_create(self)
      hash[field.es_code] = value if value
    end
  end

  def get_number_of_admin_membership
    self.memberships.where(:admin => true).count
  end

  def self.public_collections
    Collection.where(:public => true)
  end

  def self.recreate_site_index collection_id
    Collection.find(collection_id).recreate_index
  end

end
