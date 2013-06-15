class Filter
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  attr_accessor :gender, :max_age, :min_age, :relationship_status, :search_by
  attr_accessor :social_network, :weights, :get_sample, :excluded_users, :included_users

  def set_weights
    if self.search_by == "likes"
      self.weights = LikeMeConfig::default_weights
    else
      self.weights = {"l" => 0, "m" => 0, "b" => 0, "v" => 0, "t" => 0, "g" => 0, "a" => 0, "i" => 0}
      self.weights[get_char(self.search_by)] = 1
    end

  end
   @@weights = 
  {
    "l" => 2,
    "m" => 1,
    "b" => 1,
    "v" => 1,
    "t" => 1,
    "g" => 1,                                             
    "a" => 1,                       
    "i" => 1,                       
                      
  }
  
  def set_params(params)
    self.min_age = params[:min_age]
    self.max_age = params[:max_age] 
    self.gender = params[:gender] unless params[:gender]=="any"
    self.relationship_status = params[:relationship_status] unless params[:relationship_status]=="any"
    self.search_by = params[:search_by]
    self.search_by = 'likes' if self.search_by == nil
    self.social_network = params[:social_network]
    self.social_network = "include everyone" if self.social_network == nil
    #self.social_network = "don\'t include friends" if self.social_network == nil 
    return self
  end
  
  def get_scope(my_id)
    self.set_weights
     
    exclude = self.excluded_users.push(my_id)    
    users = User.where('users.id NOT IN (?)', exclude) #to exclude self
    friends_id_array = User.find(my_id).friends.map(&:id) unless self.social_network == "include everyone"
    users = users.where(:id => friends_id_array) if self.social_network == "include only friends"    
    users = users.where(['users.id NOT IN (?)', friends_id_array]) if self.social_network == "don\'t include friends"
    
    #users = remove_non_valid_users(users)
    
    users = users.where(:gender => self.gender) unless self.gender.blank?
    users = users.where("age <= ?", self.max_age) unless self.max_age.blank? #todo: if you didn't give your age to facebook it is set to zero
    users = users.where("age >= ?", self.min_age) unless self.min_age.blank?
    users = users.where(:relationship_status => self.relationship_status) unless (self.relationship_status.blank? || self.relationship_status == 'single or unspecified')    
    users = users.where("relationship_status = 'Single' OR relationship_status IS NULL") if self.relationship_status == 'single or unspecified'
    self.set_users(my_id,users)
    
    if self.get_sample
      users = users.sample(LikeMeConfig::maximal_matches)
    end
    
    users_id = users.map(&:id)
    users_id = users_id | self.included_users unless self.included_users == nil
    
    #second go, so we exclude users we included that don't fit the filter
    
    
    
    users = User.where(:id => users_id)
    if self.search_by == 'likes'
      users = users.includes(:user_page_relationships)
    else
      users = users.includes(:user_page_relationships).where("user_page_relationships.relationship_type = ? OR user_page_relationships.relationship_type = ?",get_char(self.search_by),'l')
    end
    #users = users.all        #this takes all te time because of the include
    return users
  end
  
  def get_char(type)
    #duplication with @@all_page_aliases and user   
    return 'l' if type == "likes"
    return 'm' if type == "music"
    return 'b' if type == "books"
    return 'v' if type == "movies"
    return 't' if type == "television"
    return 'g' if type == "games"
    return 'a' if type == "activities"
    return 'i' if type == "interests"
    return 'x' #shouldn't happen   
  end
  
  def initialize
      self.get_sample = true
      self.excluded_users = []
  end

  def set_users(id,users)
    self.excluded_users = Score.where(:user_id => id, :category => get_char(self.search_by)).map(&:friend_id)
    self.included_users = Score.where(:user_id => id, :category => get_char(self.search_by), :friend_id => users).order("score").last(LikeMeConfig::number_of_precalculated_friends).map(&:friend_id)
=begin    
    friends_id_array = User.find(id).friends.map(&:id) unless self.social_network == "include everyone"
    
   
    if self.social_network == "include only friends"
      self.excluded_users = Score.where(:user_id => id, :category => get_char(self.search_by)).map(&:friend_id)
      self.included_users = Score.where(:user_id => id, :category => get_char(self.search_by), :friend_id => friends_id_array).order("score").last(LikeMeConfig::number_of_precalculated_friends).map(&:friend_id)
    end
    
    if self.social_network == "don\'t include friends"
      self.excluded_users = Score.where(:user_id => id, :category => get_char(self.search_by)).map(&:friend_id)
      include = Score.where(:user_id => id, :category => get_char(self.search_by)).order("score")
      include = include.where(['scores.friend_id NOT IN (?)', friends_id_array])
      include = include.order("score").last(LikeMeConfig::number_of_precalculated_users).map(&:friend_id)
      self.included_users = include    
    end
    
    if self.social_network == "include everyone"
      self.excluded_users = Score.where(:user_id => id, :category => get_char(self.search_by)).map(&:friend_id)
      self.included_users = Score.where(:user_id => id, :category => get_char(self.search_by)).order("score").last(LikeMeConfig::number_of_precalculated_users).map(&:friend_id)
    end
    
    self.remove_non_valid_users_from_include
=end   
  end
  
  def remove_non_valid_users(users)
    users = User.where(:id => self.included_users)
    users = users.where(:gender => self.gender) unless self.gender.blank?
    users = users.where("age <= ?", self.max_age) unless self.max_age.blank? #todo: if you didn't give your age to facebook it is set to zero
    users = users.where("age >= ?", self.min_age) unless self.min_age.blank?
    users = users.where(:relationship_status => self.relationship_status) unless (self.relationship_status.blank? || self.relationship_status == 'single or unspecified')    
    users = users.where("relationship_status = 'Single' OR relationship_status IS NULL") if self.relationship_status == 'single or unspecified'
    return users
  end
  
  def persisted?
    false
  end
  
end
