class StandardDomains < ActiveRecord::Migration
  def self.up
    add_column :headers, :standard_domain, :text
    add_column :querystringparameters, :standard_domain, :text
    add_column :cookieparameters, :standard_domain, :text
    add_column :postparameters, :standard_domain, :text

    add_column :headers, :custom_domain, :text
    add_column :querystringparameters, :custom_domain, :text
    add_column :cookieparameters, :custom_domain, :text
    add_column :postparameters, :custom_domain, :text

    remove_column :headers, :domain
    remove_column :querystringparameters, :domain
    remove_column :cookieparameters, :domain
    remove_column :postparameters, :domain
  end

  def self.down
    remove_column :headers, :standard_domain
    remove_column :querystringparameters, :standard_domain
    remove_column :cookieparameters, :standard_domain
    remove_column :postparameters, :standard_domain

    remove_column :headers, :custom_domain
    remove_column :querystringparameters, :custom_domain
    remove_column :cookieparameters, :custom_domain
    remove_column :postparameters, :custom_domain

    add_column :headers, :domain, :text
    add_column :querystringparameters, :domain, :text
    add_column :cookieparameters, :domain, :text
    add_column :postparameters, :domain, :text
  end
end
