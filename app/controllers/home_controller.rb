class HomeController < ApplicationController
  def index
    #@graph = Koala::Facebook::API.new
    #@obj = @graph.get_object("koppel")
    #@pgraph = Koala::Facebook::API.new("AAAFHkL4f2AwBAHdnB19h4jsjkdaZC3e5J1WeXCkrA5opEcy9slZBebY7ZAZCJVIB8I9hpMPkWIZBGCK09auVU7cnFT8zh03mHj8XPpI99ogZDZD")
    #@pobj = @pgraph.get_connections("me", "books")  
    #@pobj = @pgraph.get_object("me")
      #req = Net::HTTP.get(URI.parse('http://localhost:3000/home/insert'))
      
      #testing
      #friends_update_string = "UPDATE users SET name = CASE id WHEN 1 THEN 'fff' WHEN 5 THEN 'ggg' END WHERE id IN (1,2)"
=begin
      ActiveRecord::Base.transaction do
        friends_update_string = "UPDATE users SET name='C', location='Z' WHERE id=1231234"
        friends_update_string2 = "UPDATE users SET name='C', location='Z' WHERE id=1231235"
        ActiveRecord::Base.connection.execute(friends_update_string)
        ActiveRecord::Base.connection.execute(friends_update_string2)
      end
      raise "here5"
=end
#name = "sd''s dcc''d"  
#ActiveRecord::Base.connection.execute("UPDATE users SET name='#{name}',gender='male',bio='I make plans, and the universe laughs. hard.' WHERE id=403087")
      #raise "fefef"
      #raise current_user.oauth_token.to_s
      #graph = Koala::Facebook::API.new(current_user.oauth_token)
      #raise graph.get_connections(690782893, "books").to_s 
      #current_user.insert_my_info_to_db(graph)
      #current_user.insert_self_data_and_likes(graph) #1.5 sec for me...
      #testing
      #ActiveRecord::Base.connection.execute("DELETE FROM user_page_relationships WHERE user_id = #{100001439566738}")
      
      
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
  
end
