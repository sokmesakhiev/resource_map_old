class Layer < ActiveRecord::Base
  include Activity::AwareConcern
  include HistoryConcern

  belongs_to :collection
  has_many :fields, order: 'ord', dependent: :destroy
  has_many :field_histories, order: 'ord', dependent: :destroy

  accepts_nested_attributes_for :fields, :allow_destroy => true

  validates_presence_of :ord

  # I'd move this code to a concern, but it works differntly (the fields don't
  # have an id). Must probably be a bug in Active Record.
  after_create :create_created_activity, :unless => :mute_activities
  def create_created_activity
    fields_data = fields.map do |field|
      hash = {'id' => field.id, 'kind' => field.kind, 'code' => field.code, 'name' => field.name}
      hash['config'] = field.config if field.config
      hash
    end
    Activity.create! item_type: 'layer', action: 'created', collection_id: collection.id, layer_id: id, user_id: user.id, 'data' => {'name' => name, 'fields' => fields_data}
  end

  before_update :record_status_before_update, :unless => :mute_activities
  def record_status_before_update
    @name_was = name_was
    @before_update_fields = fields.all
    @before_update_changes = changes.dup
  end

  after_update :create_updated_activity, :unless => :mute_activities
  def create_updated_activity
    layer_changes = changes.except('updated_at').to_hash

    after_update_fields = fields.all

    added = []
    changed = []
    deleted = []

    after_update_fields.each do |new_field|
      old_field = @before_update_fields.find { |f| f.id == new_field.id }
      if old_field
        hash = field_hash(new_field)
        really_changed = false

        ['name', 'code', 'kind', 'config'].each do |key|
          if old_field[key] != new_field[key]
            really_changed = true
            hash[key] = [old_field[key], new_field[key]]
          end
        end

        changed.push hash if really_changed
      else
        added.push field_hash(new_field)
      end
    end

    @before_update_fields.each do |old_field|
      new_field = after_update_fields.find { |f| f.id == old_field.id }
      deleted.push field_hash(old_field) unless new_field
    end

    layer_changes['added'] = added if added.present?
    layer_changes['changed'] = changed if changed.present?
    layer_changes['deleted'] = deleted if deleted.present?

    Activity.create! item_type: 'layer', action: 'changed', collection_id: collection.id, layer_id: id, user_id: user.id, 'data' => {'name' => @name_was || name, 'changes' => layer_changes}
  end

  after_destroy :create_deleted_activity, :unless => :mute_activities, :if => :user
  def create_deleted_activity
    Activity.create! item_type: 'layer', action: 'deleted', collection_id: collection.id, layer_id: id, user_id: user.id, 'data' => {'name' => name}
  end

  def history_concern_foreign_key
    self.class.name.foreign_key
  end

  # Returns the next ord value for a field that is going to be created
  def next_field_ord
    field = fields.pluck('max(ord) as o').first
    field ? field.to_i + 1 : 1
  end

  def get_associated_threshold_ids

    layerFieldIDs = self.fields.map { |field| field.id}
    associated_threshold_ids = []

    self.collection.thresholds.map { |threshold|

      thresholdFieldIDs = threshold.conditions.map { |condition| condition['field'].to_i}

      if (layerFieldIDs - thresholdFieldIDs).length < layerFieldIDs.length
        associated_threshold_ids.push(threshold.id)
      end

    }

    associated_threshold_ids

  end

  def decode_raw_layer layer
    data = layer.except('fields')
    data['fields_attributes'] =  {}
    layer['fields'].each_with_index do |field,index|
      data['fields_attributes'][index] = field.except('id')
      data['fields_attributes'][index]['collection_id'] = collection_id
    end
    data
  end

  private

  def field_hash(field)
    field_hash = {'id' => field.id, 'code' => field.code, 'name' => field.name, 'kind' => field.kind}
    field_hash['config'] = field.config if field.config.present?
    field_hash
  end

end
