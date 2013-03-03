class Filter
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  attr_accessor :gender, :max_age, :min_age #friends,
  
  
  def get_max_age
    conditions = ""
    conditions += ":gender => #{self.gender}" unless self.gender==nil
    
    return conditions
  end
  
  def persisted?
    false
  end
  
end
