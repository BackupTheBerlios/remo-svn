def display_rules_detailitem (page, request)
	# The Rules Request Detailarea has 2 forms according to http://remo.netnea.com/twiki/bin/view/Main/Task14Start
	# - Empty form in order to add a new request
	# - Displaying an existing request
	if request.nil?
		page.replace_html("requestitem", :partial => "request_rules_detailarea_empty", :object => request)
	else
		page.replace_html("requestitem", :partial => "request_rules_detailarea_detailrequest", :object => request)
	end
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
