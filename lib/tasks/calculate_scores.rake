desc "calc..."
task :calculate_scores => :environment do
  filter = Filter.new
  filter.social_network = LikeMeConfig::pre_calculation_network #"include everyone"
  
  user = User.find(ENV["USER_ID"])
  
  LikeMeConfig::all_page_types.each do |category|
    filter.search_by = category
    user.calculate_scores(filter)
  end
  
  #user = User.find(584663600)
  #user = User.find(ENV["USER_ID"])
  #graph = Koala::Facebook::API.new(user.oauth_token) #ENV["GRAPH"]
  #graph = ENV["GRAPH"]
  #user.insert_my_info_to_db(graph)
end