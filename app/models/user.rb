class User < ActiveRecord::Base
    attr_accessible :active, :name, :uid, :last_fb_update
  
  has_many :user_page_relationships
  has_many :pages , :through => :user_page_relationships
  
  
  @@all_page_types = ["likes","music","books","movies","television","games","athletes","activities","interests"] #add: Sports teams, Favourite sports and Inspirational People
  @@weights =      #let users adjust it later
  {
    "likes" => 4,
    "music" => 1,
    "books" => 1,
    "movies" => 1,
    "television" => 1,
    "games" => 0,                       
    "athletes" => 0,                       
    "activities" => 0,                       
    "interests" => 0,                       
                      
  }

  
  
  
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
    @@all_page_types.each do |type|
      insert_friend_pages(my_graph,db_friend,type) 
    end
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
  
  def match_by_most_shared_pages
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
  
  def find_matches#(filter)  #main matching algorithm      
    users = User.all #.where(filter)
    user_type_scores = Hash.new
    users_scores = Hash.new
    users.each do |user|
      @@all_page_types.each do |type|
        user_type_scores[type] = my_type_score_with(user,type)*@@weights[type].to_f unless (@@weights[type] == 0)
      end
      user_total_score = user_type_scores.values.inject{ |sum, el| sum + el }.to_f / user_type_scores.values.size
      users_scores[user.uid] = user_total_score
      user_type_scores = Hash.new

    end
    users_scores = users_scores.sort_by { |uid, score| score }
    return users_scores.reverse
  end
  
  def my_type_score_with(user,type) #todo: 4 db calls that can be reduced to 2 in exchange for readability
    my_favorites_pid = self.user_page_relationships.where(:relationship_type => type).map(&:page_id)
    user_likes_pid = user.user_page_relationships.where(:relationship_type => "likes").map(&:page_id)
    
    user_favorites_pid = user.user_page_relationships.where(:relationship_type => type).map(&:page_id)   
    my_likes_pid = self.user_page_relationships.where(:relationship_type => "likes").map(&:page_id)
    
    my_score = ((my_favorites_pid & user_likes_pid).count.to_f)/(my_favorites_pid.count + 1)
    user_score = ((user_favorites_pid & my_likes_pid).count.to_f)/(user_favorites_pid.count + 1)
    
    return (my_score+user_score)/2.0  
  end

  
  
  
end
