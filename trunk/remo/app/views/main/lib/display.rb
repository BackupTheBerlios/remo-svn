def display_rules_detailitem (page, request)
	page.replace_html("requestitem", :partial => "request_rules_detailarea", :object => request)
end

def display_rules_status (page, message)
	page.replace_html("rules-statusarea", message)
end

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
