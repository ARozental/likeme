class Event < ActiveRecord::Base
  attr_accessible :name, :location, :details, :start_time, :end_time
end 
