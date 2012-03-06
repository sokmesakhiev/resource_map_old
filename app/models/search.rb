class Search
  class << self
    attr_accessor :page_size
  end
  Search.page_size = 50

  def initialize(collection_id)
    @search = Collection.new_tire_search(collection_id)
    @search.size self.class.page_size
    @from = 0
  end

  def page(page)
    @search.from((page - 1) * self.class.page_size)
    self
  end

  def eq(property, value)
    @search.filter :term, property => value
    self
  end

  ['lt', 'lte', 'gt', 'gte'].each do |op|
    class_eval %Q(
      def #{op}(property, value)
        @search.filter :range, property => {#{op}: value}
        self
      end
    )
  end

  def op(op, property, value)
    case op.to_s.downcase
    when '<', 'l' then lt(property, value)
    when '<=', 'lte' then lte(property, value)
    when '>', 'gt' then gt(property, value)
    when '>=', 'gte' then gte(property, value)
    when '=', '==', 'eq' then eq(property, value)
    else raise "Invalid operation: #{op}"
    end
    self
  end

  def where(properties = {})
    properties.each { |property, value| eq(property, value) }
    self
  end

  def results
    @search.sort { by 'updated_at', 'desc' }
    @search.perform.results
  end
end
