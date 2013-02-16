class UserPageRelationship < ActiveRecord::Base
  attr_accessible :user_id, :page_id, :fb_created_time, :relationship_type
  belongs_to :user#, :foreign_key => 'user_id' 
  belongs_to :page#, :foreign_key => 'page_id'
  #validates_presence_of :user_id sets 0 insted of null
  #set_primary_key :id

end
