class LikeMeConfig
  
  def self.insertion_cores
    return 3
  end
  
  def self.matching_cores
    return 3
  end
  
  def self.minimal_update_time
    return 60*60*24
  end
  
  
  def self.maximal_matches #how many random users to calculate
    return 1000
  end
  
  def self.number_of_precalculated_users  #how many of best precalculated non friends to add
    return 50
  end
  
  def self.number_of_precalculated_friends #how many of best precalculated friends to add
    return 50
  end   
  
  def self.default_weights
    weights = {"l" => 2, "m" => 1, "b" => 1, "v" => 1, "t" => 1, "g" => 1, "a" => 1, "i" => 1}
  end
  
  def self.all_page_types
    return ["likes","music","books","movies","television","games","activities","interests"]
  end
  
  def self.all_page_aliases
    return ["l","m","b","v","t","g","a","i"]
  end
  
  def self.pre_calculation_network
    return "include only friends"
  end

end