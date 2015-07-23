# module Collection::TireConcern
#   extend ActiveSupport::Concern

#   included do
#     after_create :create_index
#     after_destroy :destroy_index
#   end

#   def create_index
#     success = index.create({
#       refresh: true,
#       mappings: { site: site_mapping }
#     })
#     raise "Can't create index for collection #{name} (ID: #{id})." unless success

#     # This is because in the tests collections are created and the
#     # fields association will almost always be empty, but it needs to
#     # be refreshed afte creating layers and fields.
#     clear_association_cache if Rails.env.test?
#   end

#   def site_mapping
#     Site::IndexUtils.site_mapping(fields)
#   end

#   def update_mapping
#     index.update_mapping site: site_mapping
#     index.refresh
#   end

#   def recreate_index
#     destroy_index
#     create_index
#     sites.each do |site|
#       site.collection = self
#       site.store_in_index refresh: false
#     end
#     index.refresh
#   end

#   def destroy_index
#     index.delete
#   end

#   def index
#     @index ||= self.class.index(id)
#   end

#   def index_name(options = {})
#     self.class.index_name id, options
#   end

#   def new_search(options = {})
#     Search.new(self, options)
#   end

#   def new_map_search
#     MapSearch.new id
#   end

#   def new_tire_search(options = {})
#     self.class.new_tire_search(id, options)
#   end

#   def new_tire_count(options = {}, &block)
#     self.class.new_tire_count(id, options, &block)
#   end

#   module ClassMethods
#     INDEX_NAME_PREFIX = Rails.env == 'test' ? "collection_test" : "collection"

#     def index_name(id, options = {})

#       if options[:snapshot_id]
#         return "#{INDEX_NAME_PREFIX}_#{id}_#{options[:snapshot_id]}"
#       end

#       if options[:user]
#         snapshot = Collection.find(id).snapshot_for(options[:user])
#         if snapshot
#           return "#{INDEX_NAME_PREFIX}_#{id}_#{snapshot.id}"
#         end
#       end

#       "#{INDEX_NAME_PREFIX}_#{id}"
#     end

#     def index(id)
#       ::Tire::Index.new index_name(id)
#     end

#     def new_tire_search(*ids, options)
#       Tire::Search::Search.new ids.map{|id| index_name(id, options)}, type: :site
#     end

#     def new_tire_count(*ids, options, &block)
#       Tire::Search::Count.new ids.map{|id| index_name(id, options)}, type: :site, &block
#     end
#   end
# end
