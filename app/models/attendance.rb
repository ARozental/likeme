class Attendance < ActiveRecord::Base
  attr_accessible :user_id ,:event_id, :rsvp_status
end
