class Filter
  attr_accessor :gender, :max_age, :min_age #friends,
  
  
  def get_max_age
    conditions = ""
    conditions += ":gender => #{self.gender}" unless self.gender==nil
    
    return conditions
  end
  
end
