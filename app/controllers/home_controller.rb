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
        
      #begin
      #raise params.to_s
        @filter||=Filter.new
        #@filter.gender=params[:gender]
        @filter.set_params(params)
        #raise params.to_s
        #raise @filter.gender.to_s
        #raise @filter.gender.to_s
        #@filter.min_age=params[:min_age]
        #@filter.max_age=params[:max_age]
        #raise @filter.gender.to_s
        #@filter.relationship_status=nil if params[:relationship_status]=="any" #move to find matches
        #@filter.gender=nil if params[:gender]=="any" #move to find matches
        @matches = @current_user.find_matches(@filter) unless @current_user==nil
        #@filter.gender=params[:gender]
        #@filter.relationship_status=params[:relationship_status]
        #raise @filter.gender.to_s
      #rescue
      #end
        #@user_graph = Koala::Facebook::API.new(current_user.oauth_token)
        #@something = @current_user.time_fb_connection(@user_graph) 
        #@me = @user_graph.get_object("me")
        #@my_likes = @user_graph.get_connections("me", "likes")
        #@my_books = @user_graph.get_connections("me", "books")
        #@other_user = @user_graph.get_object("681317849")
        #@other_user = @user_graph.get_object("403087")
        #@other_user_likes = @user_graph.get_connections("403087", "likes")

  
  end
end
