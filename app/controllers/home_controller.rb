class HomeController < ApplicationController
  layout "search"
  def index
      #graph = Koala::Facebook::API.new(current_user.oauth_token)
      
      #events_id_array = [172924376226214,545259285509975]
      #current_user.insert_events(events_id_array,graph)
      #raise "here"
      #raise graph.get_connections("me", "events", :limit => 999).to_s
      #raise graph.get_object("718437381516160").to_s #how attends an event
      #raise graph.get_object("172924376226214/maybe").count.to_s #how may attend an event
      #me = graph.get_object("584663600")
      #racheleah = graph.get_object("509235222")
      #raise me.to_s  
      #my_friends_id = graph.get_connections("me", "friends")
      #raise my_friends_id.to_s 
      #current_user.insert_self_data_and_likes(graph)
      #current_user.insert_my_info_to_db(graph)
       #1.5 sec for me...
      #testing
      #ActiveRecord::Base.connection.execute("DELETE FROM user_page_relationships WHERE user_id = #{100001439566738}")
      #User.where("lower(name) like ?", "%alon%").pluck(:name)

      #redirect_to "/users" doesn't leave the iframe
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
      
      #begin
        @filter||=Filter.new 
        @filter.set_params(params)
        @matches = @current_user.find_matches(@filter) unless @current_user==nil
      #rescue
      #end  
  end

  def ajax_matching
    #logger.debug params
    #@current_user = current_user
    #I don't get the right filter and it makes a new one
    @current_user = current_user
    @filter||=Filter.new
    @filter.set_params(params)
    @matches = @current_user.find_matches(@filter) unless @current_user==nil
    #logger.debug "HERE"
    #logger.debug @current_user.to_s
    #logger.debug @filter.to_s
    #logger.debug @matches.to_s
    #logger.debug "HERE"
    
    respond_to do |format|      
      #just to see it works
      format.json { render json: @matches, status: :created}
    end
  end
  
  def ajax_events
    logger.debug params

    
    @current_user = current_user
    @event_filter ||= EventFilter.new
    @users_filter ||= Filter.new #the set function will take the same name for both
    @event_filter.set_params(params)
    @users_filter.set_params(params)
    @users_filter.search_by = "likes" #todo: delete this
    #todo: change location and name attributes here??
    
    @events = @current_user.find_events(@event_filter,@users_filter)

    
    respond_to do |format|      
      format.json { render json: @events, status: :created}
    end
  end
  
  def pages
    
    redirect_to "/../auth/facebook" unless current_user
    
    @current_user = current_user
    @page_filter ||= PageFilter.new
    #@page_filter.search_for = 'television'
    @page_filter.set_params(params)
    #raise @page_filter.recommended_by
    @pages = @current_user.find_pages(@page_filter) unless @current_user==nil
    #raise Koala::Facebook::API.new(current_user.oauth_token).get_object(@pages.first[0]).to_s
    #raise @pages.to_s
  end
  
  def events
    redirect_to "/../auth/facebook" unless current_user    
    @current_user = current_user
    @event_filter ||= EventFilter.new
    @users_filter ||= Filter.new
    
    @event_filter.set_params(params) #todo: write this function
    users_params = params
    users_params["name"] = nil #so we won't limit to users with the event name
    #raise params.to_s
    @users_filter.set_params(users_params)
    #raise params["with_friends"].to_s
    #raise @event_filter.with_friends
    @events = @current_user.find_events(@event_filter,@users_filter)
  end
  
end
