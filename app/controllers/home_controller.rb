class HomeController < ApplicationController
  def index
    #@graph = Koala::Facebook::API.new
    #@obj = @graph.get_object("koppel")
    #@pgraph = Koala::Facebook::API.new("AAAFHkL4f2AwBAHdnB19h4jsjkdaZC3e5J1WeXCkrA5opEcy9slZBebY7ZAZCJVIB8I9hpMPkWIZBGCK09auVU7cnFT8zh03mHj8XPpI99ogZDZD")
    #@pobj = @pgraph.get_connections("me", "books")  
    #@pobj = @pgraph.get_object("me")
      #req = Net::HTTP.get(URI.parse('http://localhost:3000/home/insert'))
      
      redirect_to "/auth/facebook" unless current_user
      begin #we have problems then the session ends
        @current_user = current_user
      rescue
        session = nil #does it fix the loop? 
        redirect_to "/auth/facebook" #loop it session exist but current user doesn't
      end     
        
      #begin #Ifail on about 1 in 8 tries due to db parallelism
        @filter||=Filter.new
        @filter.set_params(params)
        @matches = @current_user.find_matches(@filter) unless @current_user==nil
      #rescue
      #end
 
  
  end
end
