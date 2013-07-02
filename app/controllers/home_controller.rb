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
      
      #this way you need to autherize first
      #@graph = Koala::Facebook::API.new(current_user.oauth_token)     
      #@graph.put_connections("me", "feed", :message => "I am writing on my wall!") 
      
      #begin #Ifail on about 1 in 8 tries due to db parallelism
        @filter||=Filter.new
        @filter.set_params(params)
        @matches = @current_user.find_matches(@filter) unless @current_user==nil
      #rescue
      #end  
  end
  def ajax_matching
    logger.debug params
    #@current_user = current_user
    #I don't get the right filter and it makes a new one
    @current_user = current_user
    @filter||=Filter.new
    @filter.set_params(params)
    @matches = @current_user.find_matches(@filter) unless @current_user==nil
    logger.debug "HERE"
    logger.debug @current_user.to_s
    logger.debug @filter.to_s
    logger.debug @matches.to_s
    logger.debug "HERE"
    
    respond_to do |format|      
      #just to see it works
      format.json { render json: @matches, status: :created}
    end
  end
end
