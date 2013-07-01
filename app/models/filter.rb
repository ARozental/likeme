class Filter
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  attr_accessor :gender, :max_age, :min_age, :relationship_status, :search_by, :chosen_users
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
    self.excluded_users = params[:excluded_users]
    #self.social_network = "don\'t include friends" if self.social_network == nil 
    return self
  end
  
  def get_scope(my_id)
    self.set_weights
    self.excluded_users = [] if self.excluded_users==nil #shouldn't happen 
    exclude = self.excluded_users.push(my_id)    
    users = User.where('users.id NOT IN (?)', exclude) #to exclude self
    friends_id_array = User.find(my_id).friends.pluck(:id) unless self.social_network == "include everyone"
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
      users_id = users.order("RANDOM()").limit(LikeMeConfig::maximal_matches).pluck(:id)
    else
      users_id = users.order("RANDOM()").pluck(:id)
    end
    #raise users_id.to_s
    #users_id = users.map(&:id)
    users_id = users_id | (self.included_users-self.excluded_users) #unless self.included_users == nil
    self.chosen_users = users_id
 
    return nil
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
  
  def get_users_query
    users_id_string = self.chosen_users.to_s
    users_id_string[0] = '('
    users_id_string[-1] = ')'
    if self.search_by == 'likes'
      query = "SELECT user_id, relationship_type, page_id FROM user_page_relationships"
      query +=" WHERE user_page_relationships.user_id IN #{users_id_string}"
    else
      char = "'"+get_char(self.search_by)+"'"
      query = "SELECT user_id, relationship_type, page_id FROM user_page_relationships"
      query +=" WHERE user_page_relationships.user_id IN #{users_id_string}"
      query +=" AND (user_page_relationships.relationship_type = 'l'" 
      query +=" OR user_page_relationships.relationship_type = #{char})"
    end
    return query 
  end
  
  def get_user_query_by_id(id)
    if self.search_by == 'likes'
      query = "SELECT user_id, relationship_type, page_id FROM user_page_relationships"
      query +=" WHERE user_page_relationships.user_id = #{id}"
    else
      char = "'"+get_char(self.search_by)+"'"
      query = "SELECT user_id, relationship_type, page_id FROM user_page_relationships"
      query +=" WHERE user_page_relationships.user_id = #{id}"
      query +=" AND (user_page_relationships.relationship_type = 'l'" 
      query +=" OR user_page_relationships.relationship_type = #{char})"
    end
    return query 
  end
  
  def initialize
      self.get_sample = true
      self.excluded_users = []
      self.included_users = []
  end

  def set_users(id,users)
    #todo: get rid of excluded users?
    #self.excluded_users = Score.where(:user_id => id, :category => get_char(self.search_by)).pluck(:friend_id)
    self.included_users = Score.where(:user_id => id, :category => get_char(self.search_by), :friend_id => users).order("score").last(LikeMeConfig::number_of_precalculated_friends).map(&:friend_id)

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
