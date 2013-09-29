class EventFilter
  include ApplicationHelper
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  attr_accessor :search_period_start, :search_period_end, :location, :name, :participant_name
  attr_accessor :with_friends, :min_attending, :max_attending
  attr_accessor :chosen_events, :excluded_events #arrays of ids 
  
  def set_params(params) #todo
    self.search_period_start = params[:search_period_start]
    self.search_period_end = params[:search_period_end]
    #self.search_period_end = Time.now + 60*60*24*7 if self.search_period_end == 'within a week'
    #self.search_period_end = Time.now + 60*60*24*30 if self.search_period_end == 'within a month'
    self.location = params[:location]
    self.name = params[:name]
    self.participant_name = params[:participant_name]
    self.with_friends = params[:with_friends]
    self.with_friends = 'include all events' if params[:with_friends] == nil
    self.min_attending = params[:min_attending]
    self.max_attending = params[:max_attending]
    self.chosen_events = params[:chosen_events]
    self.excluded_events = params[:excluded_events]
    return self
  end  
  
  #todo:
  #set filter: remove precalculated events
  #get friends events
  #if not enough add random events
  def get_events(user)
    events = Event
    self.excluded_events = [] if self.excluded_events==nil #shouldn't happen 
    events = events.where('events.id NOT IN (?)', self.excluded_events) unless self.excluded_events.blank?
    timestamp_search_period_end = Time.now + 60*60*24 if self.search_period_end == 'today'
    timestamp_search_period_end = Time.now + 60*60*24*7 if self.search_period_end == 'within a week'
    timestamp_search_period_end = Time.now + 60*60*24*30 if self.search_period_end == 'within a month'
    events = events.where("start_time <= ?", timestamp_search_period_end) unless self.search_period_end.blank?
    events = events.where("end_time >= ?", self.search_period_start) unless self.search_period_start.blank?
    events = events.where("end_time >= ?", Time.now)
    events = events.where("lower(location) like ?", "%#{self.location.downcase}%") unless self.location.blank?
    events = events.where("lower(name) like ?", "%#{self.name.downcase}%") unless self.name.blank?
    
    unless self.participant_name.blank? #limit to event with spesific participant, todo: can be done in 1 query...
    participant_id_array = User.where("lower(name) like ?", "%#{self.participant_name.downcase}%").pluck(:id)
    participant_events_id_array = Attendance.where(:user_id => participant_id_array).pluck(:event_id)
    #raise participant_events_id_array.to_s

    events = events.where(:id => participant_events_id_array)    
    end
    
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
