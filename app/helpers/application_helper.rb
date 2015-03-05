module ApplicationHelper
  include KnockoutHelper

  def google_maps_javascript_include_tag
    javascript_include_tag(raw("http://maps.googleapis.com/maps/api/js?libraries=geometry&sensor=false&key=#{GoogleMapsKey}&v=3.9"))
  end

  def leave_collection_permission?
    flag = false
    if !collection_admin? || collection.get_number_of_admin_membership > 1
      p collection.get_number_of_admin_membership
      flag = true
    end
    flag
  end

  def collection_admin?
    @collection_admin = current_user.admins?(collection) if @collection_admin.nil?
    @collection_admin
  end

  def render_plugin_hook(plugin, name, args = {})
    result = ''
    plugin.hooks[name].each do |view|
      result << render(view, args)
    end
    result.html_safe
  end

  def render_hook(collection, name, args = {})
    result = ''
    collection.each_plugin do |plugin|
      result << render_plugin_hook(plugin, name, args)
    end
    result.html_safe
  end

  def field_edit_view(kind)
    Field::plugin_kinds.has_key?(kind) ? Field::plugin_kinds[kind][:edit_view] : "collections/fields/#{kind}_edit_view"
  end

  def show_language_options
    languages = Language.all.map do |language|
      link_to language.name, 'javascript:void(0);', data: {locale: language.code}, style: 'font-size:12px;'
    end
    languages.join(' | ').html_safe
  end
end
