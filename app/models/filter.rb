class Filter
  attr_accessor :gender #friends, max_age, min_age...
  
  
  def get_conditions
    conditions = ""
    conditions += ":gender => #{self.gender}"
    
    #conditions += "   DONE"
  end
end
