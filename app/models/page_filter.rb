class PageFilter
  include ApplicationHelper
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  attr_accessor :search_for, :included_users, :relevant_pages, :recommended_by, :excluded_users, :chosen_users   
  
  def get_user_page_relationships
    users_id_string = self.chosen_users.to_s #todo if not empty
    users_id_string[0] = '('
    users_id_string[-1] = ')'
    
    self.search_for = "likes" if self.search_for == nil
    char = "'"+get_char(self.search_for)+"'"
    query = "SELECT user_id, relationship_type, page_id FROM user_page_relationships"
    query +=" WHERE user_page_relationships.user_id IN #{users_id_string}"
    query +=" AND user_page_relationships.relationship_type = #{char}" 
    results = ActiveRecord::Base.connection.execute(query)
    return results
  end
  
  def set_params(params)
    self.search_for = params[:search_for]
    self.search_for = 'likes' if self.search_for == nil
    self.recommended_by = params[:recommended_by]
    self.recommended_by = "people like me" if self.recommended_by == nil
    self.relevant_pages = params[:relevant_pages] #to do pages I don't know
    #self.social_network = "don\'t include friends" if self.social_network == nil
    return self
  end
  
  def persisted?
    false
  end

end