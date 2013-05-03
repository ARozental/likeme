class Filter
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  attr_accessor :gender, :max_age, :min_age, :relationship_status, :search_by, :social_network
  
  
  def set_params(params)
    self.min_age = params[:min_age]
    self.max_age = params[:max_age] 
    self.gender = params[:gender] unless params[:gender]=="any"
    self.relationship_status = params[:relationship_status] unless params[:relationship_status]=="any"
    self.search_by = params[:search_by]
    self.social_network = params[:social_network]      
    return self
  end
  
  def get_scope(id)
    #raise self.friends
    if self.search_by == 'likes'
      users = User.includes(:user_page_relationships)
    else
      users = User.includes(:user_page_relationships).where("user_page_relationships.relationship_type = ?",self.search_by)
    end
    
    
    users = users.where(['id NOT IN (?)', [id]]) #to exclude self
    friends_id_array = User.find(id).friends.map(&:id) unless self.social_network == "include everyone"
    users = users.where(:id => friends_id_array) if self.social_network == "include only friends"    
    users = users.where(['id NOT IN (?)', friends_id_array]) if self.social_network == "don\'t include friends"
    
    users = users.where(:gender => self.gender) unless self.gender.blank?
    users = users.where("age <= ?", self.max_age) unless self.max_age.blank? #todo: if you didn't give your age to facebook it is set to zero
    users = users.where("age >= ?", self.min_age) unless self.min_age.blank?
    users = users.where(:relationship_status => self.relationship_status) unless (self.relationship_status.blank? || self.relationship_status == 'single or unspecified')    
    users = users.where("relationship_status = 'Single' OR relationship_status IS NULL") if self.relationship_status == 'single or unspecified'
    #users = users.sample(n) to make it run faster
    return users
  end
  
  
  def persisted?
    false
  end
  
end
