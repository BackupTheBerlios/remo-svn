# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def in_place_select_editor_field(object,
                                   method,
                                   tag_options = {},
                                   in_place_editor_options = {})
    tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag_options = { :tag => "span",
                    :id => "#{object}_#{method}_#{tag.object.id}_in_place_editor",
                    :class => "in_place_editor_field"}.merge!(tag_options)
    in_place_editor_options[:url] =
      in_place_editor_options[:url] ||
      url_for({ :action => "set_#{object}_#{method}", :id => tag.object.id })
    tag.to_content_tag(tag_options.delete(:tag), tag_options) +
      in_place_select_editor(tag_options[:id], in_place_editor_options)
  end

  def in_place_select_editor(field_id, options = {})
    select_options = options[:select_options].map{|opt| escape_javascript(opt)}
    options[:click_to_edit_text] = "click to edit" if options[:click_to_edit_text].nil?
    function = "new Ajax.InPlaceSelectEditor(" 
    function << "'#{field_id}', " 
    function << "'#{url_for(options[:url])}' " 
    function << (', ' + options_for_javascript(
        {
        'selectOptionsHTML' => " new Array('"+ select_options.join("','") + "')",
        'clickToEditText' => "'" + options[:click_to_edit_text] + "'"
        }
      )
    ) if options[:select_options]

    function << ' )'
    javascript_tag(function)
  end

end
