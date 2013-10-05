class SessionsController < ApplicationController
  def create
    #here we are already outside the iframe
    user = User.from_omniauth(env["omniauth.auth"])
    session[:user_id] = user.id
    graph = Koala::Facebook::API.new(current_user.oauth_token)
                                 #raise graph.get_connections("me", "friends").to_s #sometimes I get no info about jenia's friends 3600062
    if (user.last_fb_update.nil? || (Time.now - user.last_fb_update)>LikeMeConfig::minimal_update_time)
    #if true
      system "rake import USER_ID=#{current_user.id} &" #import and calculate scores
      Process.detach($?.pid)    
      current_user.insert_self_data_and_likes(graph)    
                                 #user.insert_my_info_to_db(graph) #the hard work #403087=dan        
     
      
      redirect_to root_url, notice: 'updating your friends data, this may take a few minutes.'
    else
      redirect_to root_url
    end    
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url
  end
end
