def unselect_listitem (page, base_classname)
  selector = "." + base_classname + "-selected"
  classname_selected = base_classname + "-selected"
  page.select(selector).each do |item|	# loop over elements matching class
    page.call 'Element.addClassName', item, base_classname
    page.call 'Element.removeClassName', item, classname_selected
  end
end

def select_listitem (page, item, base_classname)
  classname_selected = base_classname + "-selected"
  page.call 'Element.addClassName', item, classname_selected
  page.call 'Element.removeClassName', item, base_classname
end
