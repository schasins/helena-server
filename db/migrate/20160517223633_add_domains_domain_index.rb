class AddDomainsDomainIndex < ActiveRecord::Migration
  def change
  	rename_column :domains, :url, :domain
    add_index :domains, :domain, :unique => true
  end
end
