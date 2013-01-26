class User < ActiveRecord::Base
  attr_accessible :active, :name, :uid, :last_fb_update, :location, :birthday, :id
  attr_accessible :hometown, :quotes, :relationship_status, :significant_other
  serialize :location
  serialize :hometown
  serialize :significant_other
  has_many :user_page_relationships
  has_many :pages , :through => :user_page_relationships
  set_primary_key :id
  #before_save :make_id
  #before_validation :make_id
  #validates_uniqueness_of :id
  
  def make_id
    self.id = self.uid
  end
  
  def trim_page_array(page_array) #doesn't really belong here
    page_hash = Hash.new
    page_array.each do |page|
      page_hash[page["id"]] = page
    end
    teimed_page_array = page_hash.values
    return teimed_page_array
  end
  
  @@all_page_types = ["likes","music","books","movies","television","games","activities","interests"] #add: Sports teams, Favourite sports and Inspirational People
  @@weights =      #let users adjust it later
  {
    "likes" => 4,
    "music" => 1,
    "books" => 1,
    "movies" => 1,
    "television" => 1,
    "games" => 0,                                             
    "activities" => 0,                       
    "interests" => 0,                       
                      
  }

  
  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |user|
      user.provider = auth.provider
      user.id = auth.uid #I changed it from user.uid = auth.uid
      user.name = auth.info.name
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.save!
    end
  end  

=begin  
  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      #user.id = 331
      user.name = auth.info.name
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.save!
    end
  end
=end

  def insert_friend_pages(my_graph,db_friend,type) #todo books and movies, not only likes
    friend_likes = my_graph.get_connections(db_friend.uid, type)
    friend_id = db_friend.id
    page_array = []
    user_page_relationship_array = []
    


    friend_likes.each do |like|
      page_array.push(Page.new(:id => like["id"],:pid => like["id"],:name => like["name"],:category => like["category"]))
      user_page_relationship_array.push(UserPageRelationship.new(:fb_created_time => like["created_time"],:relationship_type => type,:user_id => friend_id,:page_id => like["id"]))
    end
    t=trim_page_array(page_array)
    
    #raise page_array.to_s if t == page_array
    
    db_friend.pages = trim_page_array(page_array)#remove duplications??
    db_friend.user_page_relationships = user_page_relationship_array
    db_friend.save                                  
  end



  

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
=begin 
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
  
  def insert_friend_info(my_graph,db_friend)    
    @@all_page_types.each do |type|
      insert_friend_pages(my_graph,db_friend,type) 
    end
  end
  #handle_asynchronously :insert_friend_info
  
  def insert_friend_to_db(fb_friend)
    db_friend = User.find_or_initialize_by_uid(fb_friend["id"])
      db_friend.update_attributes({
         :id => fb_friend["id"],
         :uid => fb_friend["id"],
         :name => fb_friend["name"],
         :location => fb_friend["location"],
         :birthday => fb_friend["birthday"],
         :hometown => fb_friend["hometown"],
         :quotes => fb_friend["quotes"],
         :relationship_status => fb_friend["relationship_status"],
         :significant_other => fb_friend["significant_other"]
      })
      return db_friend      
  end
  
  def insert_my_info_to_db(my_graph)
    #my user to db
    fb_me = my_graph.get_object("me")
    db_me = insert_friend_to_db(fb_me)
    insert_friend_info(my_graph,db_me)
    
    #my friends to db
    my_friends = my_graph.get_connections("me", "friends")
    my_friends.each do |fb_friend|
      db_friend = insert_friend_to_db(fb_friend)
      insert_friend_info(my_graph,db_friend) #unless db_friend.last_fb_update was shortly #work on worker
    end
  end
  #handle_asynchronously :insert_my_info_to_db

  
  
  
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
  
  def find_matches_old#(filter)  #main matching algorithm, returns sorted hash of {uid => score}      
    users = User.all#.sample(7) #.where(filter)
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



  def find_matches#(filter)  #main matching algorithm, returns sorted hash of {uid => score} 
    users = User.includes(:user_page_relationships)#.where(:id => "509235222") #.where(filter)sample(5)
    my_pages = self.user_page_relationships.group_by(&:relationship_type) #hash: key=type, value=array of pages
    @@all_page_types.each {|t|  my_pages[t] ||= []  } 

       
    
    
    user_type_scores = Hash.new
    users_scores = Hash.new
    users.each do |user|
      user_pages = user.user_page_relationships.group_by(&:relationship_type)
      if user_pages.blank?
        user_type_scores = [0.0]
      else
        user_type_scores = user_pages.map do |type, page_array| #error if no likes
          next if (@@weights[type] == 0)        
          my_score = ((my_pages[type] & user_pages['likes']).count.to_f)/(my_pages[type].count + 1)
          user_score = ((user_pages[type] & my_pages['likes']).count.to_f)/(user_pages[type].count + 1)
          score = ((my_score+user_score) / 2.0) * @@weights[type].to_f
          score  
        end
      end
      user_type_scores.compact!
      user_total_score = user_type_scores.inject{ |sum, el| sum + el }.to_f / user_type_scores.size
      users_scores[user.uid] = user_total_score
      #user_type_scores = Hash.new

    end
    #users_scores = users_scores.sort_by { |uid, score| score }
    return users_scores#.reverse
  end 
  
  
end
