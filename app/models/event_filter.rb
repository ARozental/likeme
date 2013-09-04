class EventFilter
  include ApplicationHelper
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  attr_accessor :search_period_start, :search_period_end, :location, :name
  attr_accessor :with_friends, :min_attending, :max_attending 
  attr_accessor :chosen_events
  
  def set_params(params) #todo
    
  end  
  
  def get_events
    events = Event.where()
    events = events.where("start_time <= ?", self.search_period_end) unless self.search_period_end.blank?
    events = events.where("end_time >= ?", self.search_period_start) unless self.search_period_start.blank?
    events = events.where("lower(location) like ?", "%#{self.location.downcase}%") unless self.location.blank?
    events = events.where("lower(name) like ?", "%#{self.name.downcase}%") unless self.name.blank?
    
    
    events_id = events.order("RANDOM()").limit(101).pluck(:id)
    self.chosen_events = events_id
    
  end
  
  def persisted?
    false
  end
end
