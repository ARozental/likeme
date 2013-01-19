class UserPageRelationship < ActiveRecord::Base
  attr_accessible :user_id, :page_id, :fb_created_time, :relationship_type
  belongs_to :user 
  belongs_to :page
end
