class User < ActiveRecord::Base
  #require 'rake'
  #Rake::Task.clear
  #Likeme::Application.load_tasks
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
    existing_friends_id = User.where(:id => my_friends_id_array).pluck(:id)
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
  
  def get_scores_array(filter) #returns an array of a [user_id, score, chosen_likes]
    filter.get_scope(self.id)
    users_id = filter.chosen_users
    slices = (users_id.count.to_f/LikeMeConfig.matching_cores.to_f).ceil.to_i
    slices = 1 if slices == 0
    sliced_users_id = users_id.each_slice(slices)
    my_query = filter.get_user_query_by_id(id)
    my_pages = ActiveRecord::Base.connection.execute(my_query)
    
    my_pages = my_pages.collect { |i| [i["relationship_type"],i["page_id"]] }
    my_pages = my_pages.group_by { |i| i.first }
    my_pages = my_pages.each do |char, likes|
      my_pages[char] = likes.collect { |i| i[1]}
    end
    my_pages.values.flatten! #do I need it, some people get [] into their pages array
         
    
    #result is an array of a [user_id, score, chosen_likes]
    #ActiveRecord::Base.connection.disconnect!
    #results = Parallel.map(sliced_users_id, :in_threads=>LikeMeConfig.matching_cores) do |user_group| #processes lose db connection after function returns
    results = sliced_users_id.collect do |user_group| #in single process
      #ActiveRecord::Base.connection.reconnect!
      temp_filter = filter
      temp_filter.chosen_users = user_group
      users_query = temp_filter.get_users_query      
      users_pages = ActiveRecord::Base.connection.execute(users_query)
      users_pages = users_pages.collect { |i| [i["user_id"],i["relationship_type"],i["page_id"]] }.group_by { |i| i.first }      

      user_score_and_chosen_likes = user_group.collect do |user_id|
        user_pages = users_pages[user_id.to_s] #nil if user has no pages
        next if (user_pages == nil )
        
        user_pages = user_pages.group_by { |i| i[1] }
        user_pages = user_pages.each do |char, likes|
          user_pages[char] = likes.collect { |i| i[2]}
        end
        #now user pages is a hash from char to an array of page ids
        user_type_scores_and_pages = @@all_page_aliases.collect do |type|
          next if (filter.weights[type] == 0 )
                    
          my_pages[type] = [] if my_pages[type].blank? 
          user_pages['l'] = [] if user_pages['l'].blank? 
          my_shared_type_pages = my_pages[type] & user_pages['l']
          my_score = (my_shared_type_pages.count.to_f)/(my_pages[type].count.to_f + 1)
          
          user_pages[type] = [] if user_pages[type].blank? 
          my_pages['l'] = [] if my_pages['l'].blank? 
          user_shared_type_pages = user_pages[type] & my_pages['l']
          user_score = (user_shared_type_pages.count.to_f)/(user_pages[type].count.to_f + 1)
          
          #raise user_score.to_s
          shared_type_pages = [my_shared_type_pages, user_shared_type_pages].flatten.uniq
          score = ((my_score+user_score).to_f / 2.0) * filter.weights[type].to_f          
          score_and_pages = [score, shared_type_pages]
        end
        user_type_scores_and_pages.compact!
        
        user_total_score = user_type_scores_and_pages.collect { |type| type[0]}
        user_total_score = user_total_score.inject{ |sum, el| sum + el }.to_f / user_total_score.size
        user_shared_pages = user_type_scores_and_pages.collect { |type| type[1]}.flatten.uniq
        #user_total_pages = user_pages.values.flatten.uniq
        user_total_pages = user_pages[get_char(filter.search_by)].uniq
        
        user_chosen_likes = user_shared_pages.flatten.uniq.shuffle
        user_chosen_likes.push(user_total_pages.shuffle)  #if I want to show 6 likes even if unrelated
        user_chosen_likes = user_chosen_likes.flatten.uniq.first(6)
         
        user_total_score = (user_total_score/(6-user_chosen_likes.size) - 0.000001*(6-user_chosen_likes.size)) if user_chosen_likes.size<6 #don't want them in the top 5

        [user_id, user_total_score, user_chosen_likes] 
      end 
      user_score_and_chosen_likes
    end
    results = results.flatten(1).compact #result.flatten(1) is an array of a [user_id, score, chosen_likes] #may have nil here, possibly
    results = results.sort_by {|array| array[1]*(-1)}
    return results
  end
  
     
  def find_matches(filter) #returns an array of [user,[chosen_likes]]
    #self.calculate_scores(filter)
    results = self.get_scores_array(filter)
    
  
    ActiveRecord::Base.connection.disconnect!
    pid = Process.fork do
      ActiveRecord::Base.establish_connection
      save_matching_scores(filter,results)
    end    
    Process.detach(pid)
    
    
    ActiveRecord::Base.establish_connection
    users_id = results.first(LikeMeConfig.number_of_users_to_show).collect {|array| array[0]}
               
    users = User.where(:id => users_id).all #errors when lots of requests...
    users = users.group_by { |user| user.id }

    outcome = []
    results.first(LikeMeConfig.number_of_users_to_show).each do |array|
      outcome << [users[array[0]].first,array[2],adjust_score(array[1])]
    end
    

    
    return outcome
  end
  
  def save_matching_scores(filter,results)
    results = self.get_scores_array(filter)
    unless results.empty?
      id = self.id
      char = get_char(filter.search_by)
      user_ids = results.collect{ |s| s[0]}
      scores = results.collect{ |s| [id,s[0],char,s[1]]}
      scores = scores.to_s.gsub('[','(').gsub(']',')').gsub('"','\'')
      scores[0] = ''
      scores[-1] = ';'
      #raise scores.to_s
      query = "INSERT INTO scores (user_id, friend_id, category, score) VALUES #{scores}"
      ActiveRecord::Base.transaction do
        Score.where(:user_id => id).where(:friend_id => user_ids).where(:category => char).delete_all
        ActiveRecord::Base.connection.execute(query)
      end
    end
  end

  def calculate_scores(filter)
    results = self.get_scores_array(filter)
    save_matching_scores(filter,results)
  end
  
  def adjust_score(score)
    return 0 if score <= 0
    score = Math.sqrt(score)
    score = score*2
    score = 1 if score > 1
    score = (score*100).to_i
  end
  


     
end
