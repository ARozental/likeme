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
  
  def self.maximal_matches
    return 200
  end
  
  def self.default_weights
    weights = {"l" => 2, "m" => 1, "b" => 1, "v" => 1, "t" => 1, "g" => 1, "a" => 1, "i" => 1}
  end

end