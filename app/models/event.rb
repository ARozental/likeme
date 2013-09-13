class Event < ActiveRecord::Base
  attr_accessible :name, :location, :description, :start_time, :end_time
end 

