class User < ActiveRecord::Base
  include UsersHelper
  attr_accessible :active, :name, :uid, :last_fb_update, :location, :birthday, :id
  attr_accessible :hometown, :quotes, :relationship_status, :significant_other
  serialize :location
  serialize :hometown
  serialize :significant_other
  has_many :user_page_relationships
  has_many :pages , :through => :user_page_relationships

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
  
  def time_fb_connection(my_graph) #change name to info->db
    my_friends = my_graph.get_connections("me", "friends")
    my_id = self.id.to_s
    id_array = [my_id]
    my_friends.each do |friend|
      id_array.push(friend["id"])
    end
    grouped_id_array = id_array.each_slice(50/(@@weights.count)).to_a #so we will have no more than 50 requests in a batch
    #return id_array
=begin     
    users_info = []
   
    grouped_id_array.each do |array| #array is a group of 6 user_ids
      batch_results = my_graph.batch do |batch_api|#array of arraies of hashes
        array.each do |id|
          @@all_page_types.each do |type|
            batch_api.get_connections(id, type)
          end          
        end   
      end
      pursed_batch = batch_results.each_slice(@@weights.count).to_a #every element is an array with all info on a user
      pursed_batch.each do |info|
        users_info.push(info)
      end             
    end
=end

    return retrive_and_save_batch(my_graph,grouped_id_array[0])
    #data_hash = Hash[id_array.zip users_info]
    #return data_hash
  end
  
  def retrive_and_save_batch(graph,users_id_array)
    batch_results = graph.batch do |batch_api|#array of arraies of hashes
      users_id_array.each do |id|
        @@all_page_types.each do |type|
          batch_api.get_connections(id, type)
        end          
      end   
    end

    pursed_batch = batch_results.each_slice(@@weights.count).to_a #every element is an array with all info on a user
    data_hash = Hash[users_id_array.zip pursed_batch] #hash of 6 users, user_id=>array of arraies the contain likes, books, movies...
    
    # save the new pages
    all_pages_id = Page.all.map(&:id) #move to save db entries   
    
    batch_likes=data_hash.values.flatten
    batch_pages = []
    batch_likes.each do |like|      
      batch_pages.push(like.tap{|x| x.delete("created_time")})
    end
    
    batch_pages = batch_pages.uniq
    batch_pages.delete_if{ |page|all_pages_id.include?(page[:id].to_i) } #faster but won't notice if the page name changes
    batch_pages.each do |page|
      page["pid"] = page["id"]
    end        
    Page.create(page_array)
    
    
    
    # save user_page_relationships
    data_hash.each do |user_id,category|
      db_friend = User.find_or_initialize_by_id(user_id) #id or uid
      db_friend.user_page_relationships = [] #########
      data_hash[user_id] = Hash[@@all_page_types.zip category]     
    end
        
    user_page_relationship_array = []
    data_hash.each do |user_id,category|
      category.each do |category_name,like_array|
        like_array.each do |like|
          user_page_relationship_array.push({:fb_created_time => like["created_time"],:relationship_type => category_name,:user_id => user_id,:page_id => like["id"]})
        end        
      end           
    end
    UserPageRelationship.create(user_page_relationship_array)
    return data_hash
  end
  
  

  
  def self.from_omniauth(auth)
    #where(auth.slice(:provider, :uid)).first_or_initialize.tap do |user|
    where(:id => auth.uid).first_or_initialize.tap do |user|
      user.provider = auth.provider
      user.uid = auth.uid 
      user.id = auth.uid#I added this line
      user.name = auth.info.name
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.save!
    end
  end  



  def insert_friend_pages(my_graph,db_friend,type) #todo books and movies, not only likes
    friend_likes = my_graph.get_connections(db_friend.uid, type)
    friend_id = db_friend.id
    page_array = []
    user_page_relationship_array = []


    friend_likes.each do |like|
      #page_array.push(Page.new(:id => like["id"],:pid => like["id"],:name => like["name"],:category => like["category"]))
      #user_page_relationship_array.push(UserPageRelationship.new(:fb_created_time => like["created_time"],:relationship_type => type,:user_id => friend_id,:page_id => like["id"]))
      page_array.push({:id => like["id"],:pid => like["id"],:name => like["name"],:category => like["category"]})
      user_page_relationship_array.push({:fb_created_time => like["created_time"],:relationship_type => type,:user_id => friend_id,:page_id => like["id"]})

    end
    all_pages_id = Page.all.map(&:id) #move
    #page_array.each{ |page| page.new_record(false) if all_pages_id.include?(page["id"])}#slower
    #page_array.each(&:save)#slower
     
    page_array.delete_if{ |page|all_pages_id.include?(page[:id].to_i) } #faster but won't notice if the page name changes        
    Page.create(page_array)
    
    #raise user_page_relationship_array.to_s
    #db_friend.user_page_relationships = user_page_relationship_array# forgets the user_id???
    db_friend.user_page_relationships = []
    #user_page_relationship_array.each(&:save)
    UserPageRelationship.create(user_page_relationship_array)
  end

  
  def insert_friend_info(my_graph,db_friend)    
    @@all_page_types.each do |type|
      insert_friend_pages(my_graph,db_friend,type) 
    end
  end
  handle_asynchronously :insert_friend_info
  
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
          my_score = ((my_pages[type].map(&:page_id) & user_pages['likes'].map(&:page_id)).count.to_f)/(my_pages[type].count + 1)
          user_score = ((user_pages[type].map(&:page_id) & my_pages['likes'].map(&:page_id)).count.to_f)/(user_pages[type].count + 1)
          score = ((my_score+user_score) / 2.0) * @@weights[type].to_f
          score  
        end
      end
      
      user_type_scores.compact!
      user_total_score = user_type_scores.inject{ |sum, el| sum + el }.to_f / user_type_scores.size
      users_scores[user.uid] = user_total_score
      #user_type_scores = Hash.new

    end
    users_scores = users_scores.sort_by { |uid, score| score }
    return users_scores.reverse
  end 
  
  
end
