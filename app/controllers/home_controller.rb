class HomeController < ApplicationController
  def index
    #@graph = Koala::Facebook::API.new
    #@obj = @graph.get_object("koppel")
    #@pgraph = Koala::Facebook::API.new("AAAFHkL4f2AwBAHdnB19h4jsjkdaZC3e5J1WeXCkrA5opEcy9slZBebY7ZAZCJVIB8I9hpMPkWIZBGCK09auVU7cnFT8zh03mHj8XPpI99ogZDZD")
    #@pobj = @pgraph.get_connections("me", "books")  
    #@pobj = @pgraph.get_object("me")
    
    
    if current_user 
      @current_user = current_user
      begin
        @user_graph = Koala::Facebook::API.new(current_user.oauth_token)
        @me = @user_graph.get_object("me")
        @my_likes = @user_graph.get_connections("me", "likes")
        @my_books = @user_graph.get_connections("me", "books")
      rescue
        redirect_to "/auth/facebook"
      end
    end
  end
end
