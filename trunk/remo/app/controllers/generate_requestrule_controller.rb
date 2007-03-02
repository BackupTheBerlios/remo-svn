require "rules_generator/main"

class GenerateRequestruleController < ApplicationController
  def index

    request = Request.find(params[:id])
    @rule = get_requestrule(request) 

    @rule.gsub!("<", "&lt;")
    @rule.gsub!(">", "&gt;")
    @rule.gsub!("\n  ", "\n&nbsp;&nbsp;")
    @rule.gsub!("\n", "<br />")

  end
end
