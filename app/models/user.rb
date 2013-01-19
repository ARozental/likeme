class User < ActiveRecord::Base
    attr_accessible :active, :name, :uid, :last_fb_update
  
  has_many :user_page_relationships
  has_many :pages , :through => :user_page_relationships
  
  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.name = auth.info.name
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.save!
    end
  end
  
  
  def insert_friend_pages(my_graph,db_friend,type) #todo books and movies, not only likes
    friend_likes = my_graph.get_connections(db_friend.uid, type)
    friend_likes.each do |like|
      db_page = Page.find_or_initialize_by_pid(like["id"])
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
  
  def insert_friend_info(my_graph,db_friend)
      insert_friend_pages(my_graph,db_friend,"music") 
      insert_friend_pages(my_graph,db_friend,"books")
      insert_friend_pages(my_graph,db_friend,"movies")
      insert_friend_pages(my_graph,db_friend,"television")
      insert_friend_pages(my_graph,db_friend,"likes")
  end
  
  def insert_my_info_to_db(my_graph)
    #my user to db
    fb_me = my_graph.get_object("me")
    db_me = User.find_or_initialize_by_uid(fb_me["id"])
      db_me.update_attributes({
         :uid => fb_me["id"],
         :name => fb_me["name"]
      })

    #my pages and relationships to db
    insert_friend_info(my_graph,db_me)
    
    #my friends to db
    my_friends = my_graph.get_connections("me", "friends")
    my_friends.each do |fb_friend|
      db_friend = User.find_or_initialize_by_uid(fb_friend["id"])
      db_friend.update_attributes({
         :uid => fb_friend["id"],
         :name => fb_friend["name"]
      })
      #friends pages and relationships to db
      insert_friend_info(my_graph,db_friend) #unless db_friend.last_fb_update #work on worker

      db_friend.update_attributes(:last_fb_update => Time.now) #update timestamp  #Time.now.to_time.to_i = stamp
    end
  end
  handle_asynchronously :insert_my_info_to_db
  
  def find_best_match
    my_pages_pid = self.pages.map(&:pid)
    users = User.all
    users_and_their_good_pages = Hash.new
    users.each do |u|
      user_pages_pid = u.pages.map(&:pid)
      user_shared_pages = user_pages_pid & my_pages_pid
      users_and_their_good_pages[u.uid] = user_shared_pages
    end
    
    sorted_users_and_their_good_pages = users_and_their_good_pages.sort_by { |uid, user_shared_pages| user_shared_pages.count }
    
    return sorted_users_and_their_good_pages.reverse
  end
  
  def find_best_match2#(filter) #todo: complete this   #should return an array of users and scores  
    my_page_relationships = self.user_page_relationships
    my_music = self.user_page_relationships.where {relationship_type = "music"}
    my_books = self.user_page_relationships.where {relationship_type = "books"}
    my_movies = self.user_page_relationships.where {relationship_type = "movies"}
    my_television = self.user_page_relationships.where {relationship_type = "television"}
    my_likes = self.user_page_relationships.where {relationship_type = "likes"}
    
    user = User.all #where filter    
  end
  
  def my_type_score_with(user,type) #todo: see if it works #4 db calls that can be traded for readability
    
    my_favorites_pid = self.user_page_relationships.where(:relationship_type => type).map(&:page_id)
    my_likes_pid = self.user_page_relationships.where('relationship_type <> ?', type).map(&:page_id)
    user_favorites_pid = user.user_page_relationships.where(:relationship_type => type).map(&:page_id)   
    user_likes_pid = user.user_page_relationships.where('relationship_type <> ?', type).map(&:page_id)
    
    #where('board_id <> ?', current_board.id) 
    #joins = ClientAddressJoin.where(:client_id => current_client.id)
    
    return nil if (my_favorites_pid.count == 0)
    my_favorites_score = ((my_favorites_pid & user_favorites_pid).count)/(my_favorites_pid.count)
    my_likes_score = ((my_favorites_pid & user_likes_pid).count)/(my_favorites_pid.count)
    my_total_score = (my_likes_score + my_favorites_score)/2.0 #todo: make it better
    
    return my_total_score if (user_favorites_pid.count == 0)
    user_favorites_score = ((user_favorites_pid & my_favorites_pid).count)/(user_favorites_pid.count)
    user_likes_score = ((user_favorites_pid & my_likes_pid).count)/(user_favorites_pid.count)
    user_total_score = (user_favorites_score + user_likes_score)/2.0 #todo: make it better

    total_score = Math.sqrt(my_total_score*user_total_score)
    return total_score
  end
  
  
end
