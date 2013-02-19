module UsersHelper
  def blaaa
    return 6
  end
end
















############################# here is some old code #############################


#fb_like looks like this:
#{"category"=>"Book", "name"=>"1984", "id"=>"111757942177556", "created_time"=>"2013-02-02T01:14:50+0000"}

#fb_user looks like this:
#{"id"=>"584663600", "name"=>"Alon Rozental", "first_name"=>"Alon", "last_name"=>"Rozental", "link"=>"http://www.facebook.com/alon.rozental.3", "username"=>"alon.rozental.3", "birthday"=>"12/20/1986", "hometown"=>{"id"=>"106371992735156", "name"=>"Tel Aviv, Israel"}, "location"=>{"id"=>"106371992735156", "name"=>"Tel Aviv, Israel"}, "quotes"=>"\"It's a man's obligation to stick his boneration in a women's separation; this sort of penetration will increase the population of the younger generation.\" \n-E. Cartman\n\nSookie.\n-Bill compton", "education"=>[{"school"=>{"id"=>"176662212386543", "name"=>"Tel Aviv University | אוניברסיטת תל-אביב"}, "year"=>{"id"=>"140617569303679", "name"=>"2007"}, "type"=>"Graduate School"}], "gender"=>"male", "relationship_status"=>"In a Relationship", "significant_other"=>{"name"=>"Jenia Skorski", "id"=>"100001439566738"}, "religion"=>"Flying Spaghetti Monsterism", "political"=>"Transhumanism", "email"=>"alonzorz1@gmail.com", "timezone"=>2, "locale"=>"en_GB", "languages"=>[{"id"=>"108405449189952", "name"=>"Hebrew"}, {"id"=>"106059522759137", "name"=>"English"}], "verified"=>true, "updated_time"=>"2013-02-04T10:26:03+0000"}


  #set_primary_key :id
  #before_save :make_id
  #before_validation :make_id
  #validates_uniqueness_of :id
  
=begin
  def time_fb_connection(my_graph)
    start_time = Time.now
    my_friends = my_graph.get_connections("me", "friends")
    my_friends.each do |fb_friend|
      @@all_page_types.each do |type|
        friend_likes = my_graph.get_connections(fb_friend["id"], type)
      end      
    end
    end_time = Time.now
    return end_time-start_time
  end
=end
    
  
  
=begin 
  def self.from_omniauth(auth)
    user = User.where(auth.slice(:provider, :uid)).first_or_initialize
    user.update_attributes({
      :provider => auth.provider,
      :uid => auth.uid,
      :id => auth.uid,
      :name => auth.info.name,
      :oauth_token => auth.credentials.token,
      :oauth_expires_at => Time.at(auth.credentials.expires_at)     
    })
  end
=end

=begin 
  def insert_friend_pages_old(my_graph,db_friend,type) #todo books and movies, not only likes
    friend_likes = my_graph.get_connections(db_friend.uid, type)
    friend_likes.each do |like|
      db_page = Page.find_or_initialize_by_id(like["id"])
      db_page.update_attributes({
               :pid => like["id"],
               :name => like["name"],
               :category => like["category"]
            })
      relationship = UserPageRelationship.find_or_initialize_by_user_id_and_page_id_and_relationship_type(db_friend.id,db_page.id,type)
      relationship.update_attributes({
         :fb_created_time => like["id"],
         :relationship_type => type
      })
    end                  
  end

  def insert_friend_pages_new(my_graph,db_friend,type) #todo books and movies, not only likes
    friend_fb_likes = my_graph.get_connections(db_friend.uid, type)
    friend_db_likes = []
    friend_id = db_friend.id
    friend_fb_likes.each do |like|
      friend_db_likes.push(Page.new(#problem, only adds 1 relationship per user, is it fixed?
        :id => like["id"],
        :pid => like["id"],
        :name => like["name"],
        :category => like["category"],        
        :user_page_relationships_attributes => [{ :fb_created_time => like["created_time"],:relationship_type => type,:user_id => friend_id,:page_id => like["id"]}]))

    end
    #raise "erroWWWWWWr" if (db_friend.pages.map(&:id) != db_friend.pages.map(&:id).uniq) we can get same page with different connections
    db_friend.pages = friend_db_likes 
    db_friend.save               
  end
=end   


  
  
  
=begin  
  def insert_my_info_to_db_old(my_graph)
    #my user to db
    fb_me = my_graph.get_object("me")
    db_me = User.find_or_initialize_by_uid(fb_me["id"])
      db_me.update_attributes({
         :uid => fb_me["id"],
         :name => fb_me["name"],
         :location => fb_me["location"]
      })

    #my pages and relationships to db
    insert_friend_info(my_graph,db_me)
    
    #my friends to db
    my_friends = my_graph.get_connections("me", "friends")
    my_friends.each do |fb_friend|
      db_friend = User.find_or_initialize_by_uid(fb_friend["id"])
      db_friend.update_attributes({
         :uid => fb_friend["id"],
         :name => fb_friend["name"],
         :location => fb_me["location"]         
      })
      #friends pages and relationships to db
      insert_friend_info(my_graph,db_friend) #unless db_friend.last_fb_update #work on worker

      db_friend.update_attributes(:last_fb_update => Time.now) #update timestamp  #Time.now.to_time.to_i = stamp
    end
  end
  #handle_asynchronously :insert_my_info_to_db
=end




=begin  
  def make_id
    self.id = self.uid
  end
  
  def existing_pages_id(page_array) #doesn't really belong here
    #remove duplications, I don't think I need it 
    page_hash = Hash.new
    page_array.each do |page|
      page_hash[page["id"]] = page
    end
    #teimed_page_array = page_hash.values
    #return teimed_page_array
    

    #set the @new_record instance variable
    all_pages_id = Page.all.map(&:pid)
    my_pages_id = page_hash.keys
    existing_pages_id = my_pages_id & all_pages_id
    return existing_pages_id
    #raise existing_pages.to_s
  end
=end  