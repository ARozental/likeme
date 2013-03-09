class Page < ActiveRecord::Base
  attr_accessible :category, :name, :user_page_relationships_attributes, :id
  
  #validates_uniqueness_of :id
  has_many :user_page_relationships
  has_many :users , :through => :user_page_relationships
  accepts_nested_attributes_for :user_page_relationships
  #set_primary_key :id
  def new_record(boolean) 
    @new_record = boolean
  end


  
end
