class User < ActiveRecord::Base
  include UsersHelper
  attr_accessible :active, :name, :uid, :last_fb_update, :location, :birthday, :id, :gender, :age
  attr_accessible :hometown, :quotes, :relationship_status, :significant_other
  serialize :location
  serialize :hometown
  serialize :significant_other
  has_and_belongs_to_many :friends, class_name: "User", 
                                     join_table: "friendships",
                                     association_foreign_key: "friend_id"
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
  
  def date_to_age(birthday) #not a methood so we can do it before save and use update attributes
    #stupid americans            
    begin
      birthday=birthday.split("/")
      month=birthday[0]
      day=birthday[1]
      birthday[0]=day
      birthday[1]=month
      birthday=birthday.join("/") 
      dob = Time.parse(birthday)
      now = Time.now.utc.to_date
      now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)           
    rescue
      return nil #because user didn't say his birthday or birth year to facebook
    end    
  end

  def insert_batches_info(my_graph,my_friends) #change name to info->db
    #my_friends = my_graph.get_connections("me", "friends")
    my_id = self.id.to_s
    id_array = [my_id]
    my_friends.each do |friend|
      id_array.push(friend["id"])
    end
    grouped_id_array = id_array.each_slice(50/(@@weights.count)).to_a #so we will have no more than 50 requests in a batch

    grouped_id_array.each do |group|
      retrive_and_save_batch(my_graph,group)
    end
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
      #batch_pages.push(like.tap{|x| x.delete("created_time")}) unless batch_pages==nil
      #for some reson there is a nil in the like array
      batch_pages << Page.new(:category=>like["category"], :name=>like["name"], :pid=>like["id"], :id=>like["id"]) unless like==nil
    end
    
    batch_pages = batch_pages.uniq
    batch_pages = batch_pages.delete_if{ |page|all_pages_id.include?(page.id.to_i) } unless batch_pages==nil #faster but won't notice if the page name changes
    batch_pages.each do |page|
      page["pid"] = page["id"]
    end 
     
    Page.import batch_pages #it is faster
    
    # save user_page_relationships
    data_hash.each do |user_id,category|
      db_friend = User.find(user_id) #should only do find 
      #db_friend.user_page_relationships = [] #does: UPDATE `user_page_relationships` SET `user_id` = NULL WHERE `user_page_relationships`.`user_id` = 584663600 AND `user_page_relationships`.`id` IN (1, 2, 3)
      ActiveRecord::Base.connection.execute('DELETE FROM `user_page_relationships` WHERE `user_page_relationships`.`user_id` = 403087')
      data_hash[user_id] = Hash[@@all_page_types.zip category]     
    end
        
    user_page_relationship_array = []
    data_hash.each do |user_id,category|
      category.each do |category_name,like_array|
        unless like_array == nil
          like_array.each do |like|
            user_page_relationship_array << UserPageRelationship.new(:relationship_type => category_name,:user_id => user_id,:page_id => like["id"])
            #user_page_relationship_array.push({:fb_created_time => like["created_time"],:relationship_type => category_name,:user_id => user_id,:page_id => like["id"]})
          end
        end        
      end           
    end
    #UserPageRelationship.create(user_page_relationship_array)
    UserPageRelationship.import user_page_relationship_array
  end
  #handle_asynchronously :retrive_and_save_batch
  

  
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



  def insert_friend_pages(my_graph,db_friend,type)
    friend_likes = my_graph.get_connections(db_friend.uid, type)
    friend_id = db_friend.id
    page_array = []
    user_page_relationship_array = []


    friend_likes.each do |like|
      #page_array.push(Page.new(:id => like["id"],:pid => like["id"],:name => like["name"],:category => like["category"]))
      #user_page_relationship_array.push(UserPageRelationship.new(:fb_created_time => like["created_time"],:relationship_type => type,:user_id => friend_id,:page_id => like["id"]))
      page_array.push({:id => like["id"],:pid => like["id"],:name => like["name"],:category => like["category"]})
      user_page_relationship_array.push({:relationship_type => type,:user_id => friend_id,:page_id => like["id"]})

    end
    all_pages_id = Page.all.map(&:id) #move
    #page_array.each{ |page| page.new_record(false) if all_pages_id.include?(page["id"])}#slower
    #page_array.each(&:save)#slower
     
    page_array.delete_if{ |page|all_pages_id.include?(page[:id].to_i) } unless page_array==nil #faster but won't notice if the page name changes        
    Page.create(page_array)
    
    #raise user_page_relationship_array.to_s
    #db_friend.user_page_relationships = user_page_relationship_array# forgets the user_id???
    db_friend.user_page_relationships = []
    #user_page_relationship_array.each(&:save)
    #todo execute disable keys
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
         :significant_other => fb_friend["significant_other"],
         :gender => fb_friend["gender"],
         :age => date_to_age(fb_friend["birthday"])
      })
      #raise fb_friend.to_s unless fb_friend["name"]=="Alon Rozental"
      return db_friend      
  end
  

  
  def insert_my_info_to_db(my_graph)
    
   
    #my user to db
    fb_me = my_graph.get_object("me")
    db_me = insert_friend_to_db(fb_me)
    #insert_friend_info(my_graph,db_me)

    my_friends_id = my_graph.get_connections("me", "friends")
    
    
    
    my_friends_id_array = []
    my_friends_id.each do |fb_friend|
      my_friends_id_array.push(fb_friend["id"])
    end    
    grouped_id_array = my_friends_id_array.each_slice(50).to_a
    my_friends = []
    grouped_id_array.each do |id_array|
      batch_results = my_graph.batch do |batch_api|#array of arraies of hashes
        id_array.each do |id|
          batch_api.get_object(id)         
        end   
      end
      my_friends.push(batch_results)
    end
    my_friends=my_friends.flatten
    
    
    my_friends.each do |fb_friend|
      db_friend = insert_friend_to_db(fb_friend)
    end
    insert_batches_info(my_graph,my_friends)
    
    #frienships
    my_id = self.id.to_s 
    my_friends_id_array = []
        my_friends_id.each do |fb_friend|
      my_friends_id_array.push("(" + my_id + "," + fb_friend["id"] + ")")
    end
    my_friends_id_string=my_friends_id_array.to_s.gsub!("\"", "")
    #do it better with db constraints and no deletion:
    ActiveRecord::Base.connection.execute("DELETE FROM friendships WHERE user_id = #{my_id}")
    ActiveRecord::Base.connection.execute("INSERT INTO friendships (user_id, friend_id) VALUES #{my_friends_id_string[1..-2]}")
    
    
  end
  #handle_asynchronously :insert_my_info_to_db

  

  def find_matches(filter)  #main matching algorithm, returns sorted hash of {uid => score}
    users = User.includes(:user_page_relationships) 
    users = users.where(:gender => filter.gender) unless filter.gender.blank?
    users = users.where("age <= ?", filter.max_age) unless filter.max_age.blank? #todo: find out if it is always valid when no age available? 
    users = users.where("age >= ?", filter.min_age) unless filter.min_age.blank?
    #users = users.sample(n) to make it run faster
    
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
      user_chosen_likes = []
      begin
      user_chosen_likes = user_pages["likes"].sample(6).map(&:page_id)
      rescue
      end
      users_scores[user.uid] = [user_total_score,user_chosen_likes]

    end
    users_scores = users_scores.sort_by { |uid, score| score[0] }
    return users_scores.reverse
  end    
end
