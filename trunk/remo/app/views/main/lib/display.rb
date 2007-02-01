def unselect_listitem (page, base_classname)
  selector = "." + base_classname + "-selected"
  page.select(selector).each do |item|	# loop over elements matching class
    page.call 'Element.class', item, base_classname
  end
end

def select_listitem (page, item, base_classname)
  page.call 'Element.class', item, base_classname + "-selected"
end
