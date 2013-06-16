desc "Import facebook data"
task :import => :environment do
  #user = User.find(584663600)
  user = User.find(ENV["USER_ID"])

  graph = Koala::Facebook::API.new(user.oauth_token) #ENV["GRAPH"]
  #graph = ENV["GRAPH"]
  user.insert_my_info_to_db(graph)
  
  #do calculate scores AFTER insert_my_info_to_db
  filter = Filter.new
  filter.social_network = LikeMeConfig::pre_calculation_network
    LikeMeConfig::all_page_types.each do |category|
    filter.search_by = category
    user.calculate_scores(filter)
  end
end
