class EventFilter
  include ApplicationHelper
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  attr_accessor :search_period_start, :search_period_end, :location, :name
  attr_accessor :with_friends, :min_attending, :max_attending
  attr_accessor :chosen_events, :excluded_events #arrays of ids 
  
  def set_params(params) #todo
    
  end  
  
  #todo:
  #set filter: remove precalculated events
  #get friends events
  #if not enough add random events
  def get_events(user)
    events = Event
    self.excluded_events = [] if self.excluded_events==nil #shouldn't happen 
    events = events.where('events.id NOT IN (?)', self.excluded_events) unless self.excluded_events.blank?
    events = events.where("start_time <= ?", self.search_period_end) unless self.search_period_end.blank?
    events = events.where("end_time >= ?", self.search_period_start) unless self.search_period_start.blank?
    events = events.where("lower(location) like ?", "%#{self.location.downcase}%") unless self.location.blank?
    events = events.where("lower(name) like ?", "%#{self.name.downcase}%") unless self.name.blank?
    #todo: more basic filtering here
    
    user_friends_id_array = user.friends.pluck(:id)
    friends_events_id_array = Attendance.where(:user_id => user_friends_id_array).pluck(:event_id)
    friends_events = events.where(:id => friends_events_id_array)
    #todo: limit number
    #todo: if number of events < max add more from "random" events, use function for it so it can be smart random
    #return the ids
    
    self.chosen_events = friends_events.order("RANDOM()").limit(LikeMeConfig.max_events_per_search).pluck(:id)
    self.add_more_events(events) if self.chosen_events.size < LikeMeConfig.max_events_per_search #than add more events
    
    return self.chosen_events
  end
  
  def add_more_events(events_scope)
    number_of_events_to_add = LikeMeConfig.max_events_per_search - self.chosen_events.size
    return self.chosen_events unless number_of_events_to_add > 0
    events_scope = events_scope.where('events.id NOT IN (?)', self.chosen_events) unless self.chosen_events.blank?
    events_scope = events_scope.where('events.id NOT IN (?)', [0]) if self.chosen_events.blank?
    new_events_ids = events_scope.order("RANDOM()").limit(number_of_events_to_add).pluck(:id)
    self.chosen_events = self.chosen_events.push(new_events_ids).flatten
    return self.chosen_events
  end
  
  
  
  def persisted?
    false
  end
end
