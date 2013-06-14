class User < ActiveRecord::Base
  include UsersHelper
  attr_accessible :active, :name, :id, :location, :birthday, :gender, :age, :bio
  attr_accessible :hometown, :quotes, :relationship_status, :significant_other, :last_fb_update
  serialize :location
  serialize :hometown
  serialize :significant_other
  has_and_belongs_to_many :friends, class_name: "User", 
                                     join_table: "friendships",
                                     association_foreign_key: "friend_id"
  has_many :user_page_relationships
  has_many :pages , :through => :user_page_relationships
  
  #@@cores = 3
  @@all_page_types = ["likes","music","books","movies","television","games","activities","interests"] #add: Sports teams, Favourite sports and Inspirational People
  @@all_page_aliases = ["l","m","b","v","t","g","a","i"] #add: Sports teams, Favourite sports and Inspirational People
  @@weights =      #let users adjust it later
  {
    "l" => 2,
    "m" => 1,
    "b" => 1,
    "v" => 1,
    "t" => 1,
    "g" => 1,                                             
    "a" => 1,                       
    "i" => 1,                       
                      
  }
  
  def description
    return "" if self.bio.blank? && self.quotes.blank?
    return self.quotes if self.bio.blank? && !(self.quotes.blank?)
    return self.bio if !(self.bio.blank?) && self.quotes.blank?
    return self.bio if self.bio.length > self.quotes.length
    return self.quotes
  end
  
  def insert_batches_info(my_graph,my_friends)
    
    my_id = self.id.to_s
    id_array = [] 
    my_friends.each do |friend|
      id_array.push(friend["id"]) unless friend==nil
    end
    users_last_fb_update = User.where(:id => id_array).map(&:last_fb_update)
    grouped_id_array = id_array.each_slice(50/(@@weights.count)).to_a #so we will have no more than 50 requests in a batch
    
    ########################################### old single processed way 
    #grouped_id_array.each do |group|
    #  retrive_and_save_batch(my_graph,group)
    #end
    Parallel.each(grouped_id_array, :in_processes => LikeMeConfig::insertion_cores) do |group|
      begin
        ActiveRecord::Base.connection.reconnect!
        retrive_and_save_batch(my_graph,group)
      rescue
      end
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
    #raise graph.get_connections("509006501", "likes").to_s   can't get data on some people...
    
    # save the new pages
    all_pages_id = Page.all.map(&:id) #todo: change so I won't take all pages to memory move to save db entries   
    batch_likes=data_hash.values.flatten
    batch_pages = []
    batch_likes.each do |like|      
      #for some reson there is a nil in the like array
      batch_pages << Page.new(:category=>like["category"], :name=>like["name"], :id=>like["id"]) unless like==nil
    end
    
    batch_pages = batch_pages.uniq
    batch_pages = batch_pages.delete_if{ |page|all_pages_id.include?(page.id.to_i) } unless batch_pages==nil #faster but won't notice if the page name changes
    batch_pages.each do |page|
      page["id"] = page["id"]
    end 
    
    Page.import batch_pages 
    
    # save user_page_relationships
    ActiveRecord::Base.transaction do
      data_hash.each do |user_id,category| #category is an array of arrays [[likes],[books],...]
        #raise category.to_s
        ActiveRecord::Base.connection.execute("DELETE FROM user_page_relationships WHERE user_id = #{user_id}")
        data_hash[user_id] = Hash[@@all_page_aliases.zip category]     
      end
      #raise data_hash.to_s    
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
      UserPageRelationship.import user_page_relationship_array
    end
  end
  #handle_asynchronously :retrive_and_save_batch
  

  
  def self.from_omniauth(auth)
    #where(auth.slice(:provider, :id)).first_or_initialize.tap do |user|
    where(:id => auth.extra["raw_info"]["id"].to_i).first_or_initialize.tap do |user|
      #raise auth.extra["raw_info"]["id"].to_s
      user.provider = auth.provider
      #user.id = auth.id 
      user.id = auth.extra["raw_info"]["id"]
      user.name = auth.info.name
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.active = true
      user.save!
    end
  end  




  def insert_friend_to_db(fb_friend)
    db_friend = User.find_or_initialize_by_id(fb_friend["id"])
      db_friend.update_attributes({
         :id => fb_friend["id"],
         :name => fb_friend["name"],
         :location => fb_friend["location"],
         :birthday => fb_friend["birthday"],
         :hometown => fb_friend["hometown"],
         :quotes => fb_friend["quotes"],
         :relationship_status => fb_friend["relationship_status"],
         :significant_other => fb_friend["significant_other"],
         :gender => fb_friend["gender"],
         :age => date_to_age(fb_friend["birthday"]),
         :bio => fb_friend["bio"]
      })
      #raise fb_friend.to_s unless fb_friend["name"]=="Alon Rozental"
      return db_friend      
  end
  
  def insert_self_data_and_likes(my_graph)
    fb_me = my_graph.get_object("me")
    db_me = insert_friend_to_db(fb_me)
    
    my_id = db_me.id
    user_page_relationship_array = []
    page_array = []
    
    batch_results = my_graph.batch do |batch_api|#todo finish
      @@all_page_types.each do |category|
        batch_api.get_connections(my_id, category)          
      end
    end   
    #raise batch_results.to_s
    category_counter = 0
    @@all_page_types.each do |category|
      my_likes = batch_results[category_counter]
      category_char = get_char(category)      
      my_likes.each do |like|
        user_page_relationship_array << UserPageRelationship.new(:relationship_type => category_char,:user_id => my_id,:page_id => like["id"]) #unless like.blank?
        page_array << Page.new(:category => like["category"], :name => like["name"], :id => like["id"]) #unless like.blank?      
      end
      category_counter = category_counter+1
    end

    #remove existing pages and duplications from page array
    existing_pages_id = Page.where(:id => page_array.map(&:id)).map(&:id)
    page_array = page_array.reject { |page|  existing_pages_id.include?(page["id"])}
    page_hash = Hash.new
    page_array.each do |page|
      page_hash[page["id"]] = page
    end
    page_array = page_hash.values    

 
    Page.import page_array unless page_array.blank?
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("DELETE FROM user_page_relationships WHERE user_id = #{my_id}")
      UserPageRelationship.import user_page_relationship_array unless user_page_relationship_array.blank?
    end

  end
  
  def insert_my_info_to_db(my_graph)
    

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
    my_friends = my_friends.flatten.compact
    
    friends_array = []
    my_friends.each do |fb_friend|
      #sometimes for some friends not all the info I can see on their profile gets to likeme from facebook... is that a privacy thing?
      friends_array << User.new(
      :id => fb_friend["id"],
      :name => fb_friend["name"],
      :location => fb_friend["location"],
      :birthday => fb_friend["birthday"],
      :hometown => fb_friend["hometown"],
      :quotes => fb_friend["quotes"],
      :relationship_status => fb_friend["relationship_status"],
      :significant_other => fb_friend["significant_other"],
      :gender => fb_friend["gender"],
      :age => date_to_age(fb_friend["birthday"]),
      :bio => fb_friend["bio"])        
    end
    
    #todo do not reject+import, use update+insert on all
    existing_friends_id = User.where(:id => my_friends_id_array).map(&:id)
    friends_array = friends_array.reject { |friend|  existing_friends_id.include?(friend["id"])}
    User.import friends_array unless friends_array.blank?
      
    #frienships
    my_id = self.id.to_s 
    my_friends_id_array = []
        my_friends_id.each do |fb_friend|
      my_friends_id_array.push("(" + my_id + "," + fb_friend["id"] + ")")
    end
    my_friends_id_string=my_friends_id_array.to_s.gsub!("\"", "")
    #do it better with db constraints and no deletion? one transaction?
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("DELETE FROM friendships WHERE user_id = #{my_id}")
      ActiveRecord::Base.connection.execute("INSERT INTO friendships (user_id, friend_id) VALUES #{my_friends_id_string[1..-2]}")
    end
    #insert friends info
    ActiveRecord::Base.connection.reconnect!
    insert_batches_info(my_graph,my_friends) #losing connection here?
    ActiveRecord::Base.connection.reconnect!
    self.last_fb_update = Time.now
    self.save!
  end
  #handle_asynchronously :insert_my_info_to_db
  
  def get_excluded_users_id_array(filter)
    scores = Score.where(:user_id => self.id, :category => get_char(filter.search_by)).order("score")
    if scores.count > 25
      users = scores.first(scores.count - 25).map(&:friend_id)
    else
      users = []
    end
  end
  
  def get_likes_to_precalculated_scores(users_id,filter)
    #I need an hash where every user_id go to [score,likes] 
    filter.excluded_users = []
    filter.include_only = users_id
    users = filter.get_scope(self.id)
    
    users_order = users.order("score").first(25)
    users = User.where(:id => users_order)
    if self.search_by == 'likes'
      users = users.includes(:user_page_relationships)
    else
      users = users.includes(:user_page_relationships).where("user_page_relationships.relationship_type = ? OR user_page_relationships.relationship_type = ?",get_char(self.search_by),'l')
    end
    
  end  

  def find_matches(filter)  #main matching algorithm, returns sorted hash of {id => score}

    excluded_users_id_array = get_excluded_users_id_array(filter)
    filter.excluded_users = excluded_users_id_array

    users = filter.get_scope(self.id) 
    
    #this takes all the time   
    my_pages = self.user_page_relationships.group_by(&:relationship_type) #hash: key=type, value=array of pages
    @@all_page_aliases.each {|t|  my_pages[t] ||= []  } 
   
    user_type_scores = []
    users_scores = Hash.new
    

    results = Parallel.map(users, :in_processes=>3) do |user|
      #shared_pages_id = [] 
      user_pages = user.user_page_relationships.group_by(&:relationship_type)
      shared_pages_id = []
      if user_pages.blank?
        user_type_scores = [0.0]
      else
        user_type_scores = []
        user_pages.map do |type, page_array| #error if no likes
          next if (filter.weights[type] == 0 ) #todo change here!

          my_pages[type] = [] if my_pages[type].empty? 
          user_pages['l'] = [] if user_pages['l'].empty? 
          my_shared_pages_id = my_pages[type].map(&:page_id) & user_pages['l'].map(&:page_id)
          my_score = (my_shared_pages_id.count.to_f)/(my_pages[type].count.to_f + 1)

          user_pages[type] = [] if user_pages[type].empty? 
          my_pages['l'] = [] if my_pages['l'].empty? 
          user_shared_pages_id = user_pages[type].map(&:page_id) & my_pages['l'].map(&:page_id)
          user_score = (user_shared_pages_id.count.to_f)/(user_pages[type].count.to_f + 1)
          
          shared_pages_id.push([my_shared_pages_id, user_shared_pages_id])
          score = ((my_score+user_score).to_f / 2.0) * filter.weights[type].to_f          
          user_type_scores.push(score)
        end
      end

      user_type_scores.compact!
      if user_type_scores.empty?
        user_total_score = 0.0
      else
        user_total_score = user_type_scores.inject{ |sum, el| sum + el }.to_f / user_type_scores.size
      end
      user_chosen_likes = []
      user_chosen_likes = shared_pages_id.flatten.uniq.shuffle
      user_chosen_likes.push(user_pages[get_char(filter.search_by)].sample(6).map(&:page_id)) unless user_pages[get_char(filter.search_by)].blank?
      user_chosen_likes = user_chosen_likes.flatten.uniq.first(6)
      #user_chosen_likes = user_pages[get_char(filter.search_by)].sample(6).map(&:page_id)
      
      user_total_score = (user_total_score/(6-user_chosen_likes.size) - 0.000001*(6-user_chosen_likes.size)) if user_chosen_likes.size<6 #don't want them in the top 5
      users_scores[user.id] = [user.id,user_total_score,user_chosen_likes]
    end
    #raise results.to_s  
    results.each do |score_array|
      users_scores[score_array[0]] = [score_array[1],score_array[2]]
    end
    
    users = users.to_a.sort_by {|user| users_scores[user["id"]][0]*(-1)}
    users_and_likes = []
    users.each do |user|
      users_and_likes << [user,users_scores[user.id][1]]
    end
    #raise users_and_likes.to_s
    #users_objects = User.where(:id => users_scores.keys).all already have it
    #raise users_scores.to_s
    users_scores = users_scores.sort_by { |id, score| score[0]*(-1) }
    #raise users_scores.to_s
    #users_order = users_scores.collect {|x| x[0]}.to_s
    #users_objects = User.where(:id => users_scores.keys)
    #return users_scores
    #raise users_and_likes.size.to_s
    #raise users_and_likes.to_s
    return users_and_likes
  end
  
  def calculate_scores(category) # similar to find_matches can write it better...
    filter = Filter.new
    filter.set_params({})
    users = filter.get_scope(self.id)
    
    filter.search_by = category
    filter.get_sample = false
    #users = filter.get_scope(self.id)
    #users = users.sample(LikeMeConfig::maximal_matches) #to make it run faster #gets the array
    my_pages = self.user_page_relationships.group_by(&:relationship_type) #hash: key=type, value=array of pages
    @@all_page_aliases.each {|t|  my_pages[t] ||= []  } 
   
    user_type_scores = []
    users_scores = Hash.new
    
    results = []
    users.each do |user| 
      user_pages = user.user_page_relationships.group_by(&:relationship_type)
      #raise user_pages.to_s if user.id = 100003977536148 
      if user_pages.blank?
        user_type_scores = [0.0]
        #raise user_pages.to_s if user.id = 100003977536148
      else
        user_type_scores = []
        user_pages.map do |type, page_array| #error if no likes
          next if (filter.weights[type] == 0 ) #todo change here!
          #raise filter.weights[type].to_s if user.id = 100003977536148
          my_pages[type] = [] if my_pages[type].empty? 
          user_pages['l'] = [] if user_pages['l'].empty? 
          my_shared_pages_id = my_pages[type].map(&:page_id) & user_pages['l'].map(&:page_id)
          my_score = (my_shared_pages_id.count.to_f)/(my_pages[type].count.to_f + 1)

          user_pages[type] = [] if user_pages[type].empty? 
          my_pages['l'] = [] if my_pages['l'].empty? 
          user_shared_pages_id = user_pages[type].map(&:page_id) & my_pages['l'].map(&:page_id)
          user_score = (user_shared_pages_id.count.to_f)/(user_pages[type].count.to_f + 1)
          
          score = ((my_score+user_score).to_f / 2.0) * filter.weights[type].to_f          
          user_type_scores.push(score)
        end
      end
      #raise user_type_scores.to_s if user.id = 100003977536148
      user_type_scores.compact!
      user_total_score = user_type_scores.inject{ |sum, el| sum + el }.to_f / user_type_scores.size
      user_chosen_likes = []
      begin
      user_chosen_likes = user_pages[get_char(filter.search_by)].sample(6).map(&:page_id) #choose whet type pf likes to show
      rescue
      end
      user_total_score = (user_total_score/(6-user_chosen_likes.size) - 0.000001*(6-user_chosen_likes.size)) if user_chosen_likes.size<6 #don't want them in the top 5
      users_scores[user.id] = [user.id,user_total_score]
      results << [user.id, user_total_score]
    end
    results.each do |score_array|
      users_scores[score_array[0]] = score_array[1]
    end
    
    #users = users.to_a.sort_by {|user| users_scores[user["id"]][0]*(-1)}
    users_scores = users_scores.sort_by { |id, score| score*(-1) }
    #raise users_scores.to_s
    score_array = []
    my_id = self.id
    users_scores.each do |user_and_score|
      score_array << Score.new(:user_id => my_id, :friend_id => user_and_score[0], :category => get_char(category), :score => user_and_score[1])
    end
    #raise score_array.to_s
    ActiveRecord::Base.transaction do
      #todo WTF WTF WTF ActiveRecord::StatementInvalid: PGError: ERROR:  column "b" does not exist
      #ActiveRecord::Base.connection.execute("DELETE FROM scores WHERE user_id = #{self.id} AND category = #{get_char(category)};")
      Score.destroy_all(:user_id => self.id, :category => get_char(category))
      Score.import score_array   
    end
  end      
end
