desc "calc..."
task :calculate_scores => :environment do
  filter = Filter.new
  filter.get_scope
  #user = User.find(584663600)
  #user = User.find(ENV["USER_ID"])
  #graph = Koala::Facebook::API.new(user.oauth_token) #ENV["GRAPH"]
  #graph = ENV["GRAPH"]
  #user.insert_my_info_to_db(graph)
end