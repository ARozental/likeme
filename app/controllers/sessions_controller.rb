class SessionsController < ApplicationController
  def create
    user = User.from_omniauth(env["omniauth.auth"])
    session[:user_id] = user.id
    graph = Koala::Facebook::API.new(current_user.oauth_token)
    user.insert_my_info_to_db(graph) #the hard work #403087=dan
    redirect_to root_url
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url
  end
end
