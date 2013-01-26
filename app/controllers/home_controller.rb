class HomeController < ApplicationController
  def index
    #@graph = Koala::Facebook::API.new
    #@obj = @graph.get_object("koppel")
    #@pgraph = Koala::Facebook::API.new("AAAFHkL4f2AwBAHdnB19h4jsjkdaZC3e5J1WeXCkrA5opEcy9slZBebY7ZAZCJVIB8I9hpMPkWIZBGCK09auVU7cnFT8zh03mHj8XPpI99ogZDZD")
    #@pobj = @pgraph.get_connections("me", "books")  
    #@pobj = @pgraph.get_object("me")
    
      begin
       
           @current_user = current_user  
        @matches = @current_user.find_matches
        @user_graph = Koala::Facebook::API.new(current_user.oauth_token)
        @me = @user_graph.get_object("me")
        @my_likes = @user_graph.get_connections("me", "likes")
        @my_books = @user_graph.get_connections("me", "books")
        @other_user = @user_graph.get_object("681317849")
        @other_user = @user_graph.get_object("403087")
        @other_user_likes = @user_graph.get_connections("403087", "likes")
        #@matches = insert_friend_pages_new(@user_graph,User.first,"likes")

      rescue
        #session[:user_id] = nil 
        #redirect_to "/auth/facebook" #loop it session exist but current user isn't
      end
    
  end
end
