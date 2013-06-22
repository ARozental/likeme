desc "calc..."
task :calculate_scores, [:id, :filter] => :environment do |t, args|
  
  #puts "Args were: #{args}"
  #rake calculate_scores[1,2]
  #args = {id => 1,filter => 2}
  id = args["id"] 
  filter = args["filter"]
  user = User.find(id)
  results = user.get_scores_array(filter)
  save_matching_scores(filter,results)
end
