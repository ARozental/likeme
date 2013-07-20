class PageFilter
  include ApplicationHelper
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  attr_accessor :search_by, :chosen_users, :relevant_pages, :social_network   
  
  def get_user_page_relationships
    users_id_string = self.chosen_users.to_s
    users_id_string[0] = '('
    users_id_string[-1] = ')'

    char = "'"+get_char(self.search_by)+"'"
    query = "SELECT user_id, relationship_type, page_id FROM user_page_relationships"
    query +=" WHERE user_page_relationships.user_id IN #{users_id_string}"
    query +=" AND user_page_relationships.relationship_type = #{char}" 
    results = ActiveRecord::Base.connection.execute(query)
    return results
  end
  
  
  def persisted?
    false
  end

end