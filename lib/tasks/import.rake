desc "Import facebook data"
task :import => :environment do
  #user = User.find(584663600)
  user = User.find(ENV["USER_ID"])

  graph = Koala::Facebook::API.new(user.oauth_token) #ENV["GRAPH"]
  #graph = ENV["GRAPH"]
  user.insert_my_info_to_db(graph)
end
