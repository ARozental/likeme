class LikeMeConfig
  
  def self.page_recommenders
    200
  end
  
  def self.page_insertion_chance
    0.05
  end
  
  def self.insertion_cores #threads now...
    return 20
  end
  
  def self.matching_cores #threads now...???
    return 6
  end
  
  def self.minimal_update_time
    return 1
  end
  
  
  def self.maximal_matches #how many random users to calculate
    return 300 #200
  end
  
  def self.number_of_precalculated_users  #how many of best precalculated non friends to add
    return 50 #50
  end
  
  def self.number_of_precalculated_friends #how many of best precalculated friends to add
    return 50 #50
  end 
    
  def self.number_of_users_to_show #to pass from find_matches
    return 100 #100
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
  
  def self.max_users_per_event
    return 30
  end
  
  def self.max_events_per_search
    return 10 #100
  end

end