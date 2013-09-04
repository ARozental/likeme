class HomeController < ApplicationController
  #autocomplete :user, :name
  def index
      #graph = Koala::Facebook::API.new(current_user.oauth_token)
      
      #events_id_array = [172924376226214,545259285509975]
      #current_user.insert_events(events_id_array,graph)
      #raise "here"
      #raise graph.get_connections("me", "events", :limit => 999).to_s
      #raise graph.get_object("172924376226214/attending", :limit => 5).to_s #how attends an event
      #raise graph.get_object("172924376226214/maybe").count.to_s #how may attend an event
      #me = graph.get_object("584663600")
      #racheleah = graph.get_object("509235222")
      #raise me.to_s  
      #my_friends_id = graph.get_connections("me", "friends")
      #raise my_friends_id.to_s 
        
      #current_user.insert_my_info_to_db(graph)
      #current_user.insert_self_data_and_likes(graph) #1.5 sec for me...
      #testing
      #ActiveRecord::Base.connection.execute("DELETE FROM user_page_relationships WHERE user_id = #{100001439566738}")
      #User.where("lower(name) like ?", "%alon%").pluck(:name)
      
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
=begin  
  def auto_complete_name
    logger.debug "asswipe"
    if params[:term]
      like= "%".concat(params[:term].concat("%"))
      users = User.where("name like ?", like)
    else
      users = User.all
    end
    list = users.map {|u| Hash[ id: u.id, label: u.name, name: u.name]}
    render json: list
  end
=end
  def ajax_matching
    logger.debug params
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
    @users_filter.search_by = "likes"
    @event_filter.set_params(params) #todo: write this function
    @events = @current_user.find_events(@event_filter,@users_filter)
  end
  
end
