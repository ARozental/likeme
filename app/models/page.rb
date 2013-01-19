class Page < ActiveRecord::Base
  attr_accessible :category, :name, :pid
  
  has_many :user_page_relationships
  has_many :users , :through => :user_page_relationships
end
