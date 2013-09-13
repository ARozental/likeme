class User < ActiveRecord::Base
  include UsersHelper
  attr_accessible :active, :name, :id, :location, :birthday, :gender, :age, :bio, :last_foregin_fb_update
  attr_accessible :hometown, :quotes, :relationship_status, :significant_other, :last_fb_update
  attr_accessible :last_relationship_status_update
  serialize :location
  serialize :hometown
  serialize :significant_other
  has_and_belongs_to_many :friends, class_name: "User", 
                                     join_table: "friendships",
                                     association_foreign_key: "friend_id"
  has_many :user_page_relationships
  has_many :pages , :through => :user_page_relationships
  has_many :events , :through => :attendance
 
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
    id_array = my_friends.map { |friend| friend["id"]} #sometimes client error form koala, usually ok after 1 refresh, this is a koala bug??
    users_last_fb_update = User.where(:id => id_array).select("id, last_foregin_fb_update").all
    users_last_fb_update.select! { |friend|  (friend.last_foregin_fb_update.nil? || (Time.now - friend.last_foregin_fb_update)>LikeMeConfig::minimal_update_time)}
    users_last_fb_update.map! {|friend| friend.id.to_s}
    grouped_id_array = users_last_fb_update.each_slice(50/(@@weights.count)).to_a #so we will have no more than 50 requests in a batch
    
    ########################################### old single processed way 
    #grouped_id_array.each { |group| retrive_and_save_batch(my_graph,group)}

    Parallel.each(grouped_id_array, :in_threads => LikeMeConfig::insertion_cores) do |group|
      begin
        ActiveRecord::Base.connection.reconnect!
        retrive_and_save_batch(my_graph,group)
      rescue
      end
    end
    #insert events
    events_grouped_id_array = users_last_fb_update.each_slice(50).to_a
    ########################################### old single processed way 
    #events_grouped_id_array.each { |group| retrive_and_save_events_batch(my_graph,group)}   
    Parallel.each(events_grouped_id_array, :in_threads => LikeMeConfig::insertion_cores) do |group|
      begin
        ActiveRecord::Base.connection.reconnect!
        retrive_and_save_events_batch(my_graph,group)
      rescue
      end
    end 
  end
  
  def save_batch_pages(data_hash)
    batch_likes=data_hash.values.flatten
    page_array = []
    #batch_pages = []
    #raise batch_likes.to_s #no good, no category char
    batch_likes.each do |like|      
      #for some reson there is a nil in the like array
      #batch_pages << Page.new(:category=>like["category"], :name=>like["name"], :id=>like["id"]) unless like==nil
      page_array << [like["category"],like["name"],like["id"]] 
    end
    #raise page_array.to_s
    page_array.uniq!
    page_id_array = []
    
    page_array.each {|page| page_id_array << page[2].to_i}       
    existing_pages_id = Page.where(:id => page_id_array).pluck(:id) #todo fix. this makes a race condition when threaded
    page_id_array = (page_id_array-existing_pages_id)
    page_array.select! { |page|  page_id_array.include?(page[2].to_i)}
    unless page_array.empty?
      page_delete_string = page_id_array.to_s
      page_delete_string[0] = '('
      page_delete_string[-1] = ')'
      page_delete_string = "DELETE FROM pages WHERE id IN #{page_delete_string}"
      page_string = "INSERT INTO pages (category,name,id) VALUES "
      page_array.each { |page|  page_string += "(\'#{page[0]}\',\'#{page[1].gsub("'", "''")}\',#{page[2]}),"}
      page_string[-1] = ';'
      begin #because of race conditions
        ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute(page_delete_string)
        ActiveRecord::Base.connection.execute(page_string)
        end
      rescue
      end
    end
  end
  
  def retrive_and_save_events_batch(graph,users_id_array)
    #group is an array of up to 50 friends ids as strings
    batch_results = graph.batch do |batch_api|#array of arraies of hashes
      users_id_array.each do |id|
        batch_api.get_connections(id, "events", :limit => 999)
      end   
    end
    #raise batch_results.to_s
    events_id_array = []
    batch_results.each do |user_events|
      unless user_events.empty?
        user_events.each do |event|
          events_id_array << event["id"]
        end
      end
    end
    events_id_array.uniq!
    self.insert_events(events_id_array,graph)
    
=begin    
    data_hash = Hash[users_id_array.zip batch_results] #hash of user id => array of his events
    attendance_array = []
    new_events_array = [] #event to insert to db
    data_hash.each do |id, event_array|
      event_array.each { |event| attendance_array<<[id,event["id"],event["rsvp_status"][0]]}
      event_array.each { |event| new_events_array<<[event["id"],event["name"],event["location"],event["start_time"],event["end_time"]]}     
    end
    
    ActiveRecord::Base.transaction do
      updated_users = attendance_array.collect{ |attendance| attendance[0]}.uniq
      Attendance.where(:user_id => updated_users).delete_all
      Attendance.import [:user_id,:event_id,:rsvp_status], attendance_array, :validate => false
    end
    ActiveRecord::Base.transaction do
      new_events_array.uniq!
      updated_events = new_events_array.collect{ |event| event[0]}
      Event.where(:id => updated_events).delete_all
      Event.import [:id,:name,:location,:start_time,:end_time], new_events_array, :validate => false
    end
=end    
  end
  
  def retrive_and_save_batch(graph,users_id_array)
    batch_results = graph.batch do |batch_api|#array of arraies of hashes
      users_id_array.each do |id|
        @@all_page_types.each do |type|
          batch_api.get_connections(id, type, :limit => 999)
        end          
      end   
    end
    pursed_batch = batch_results.each_slice(@@weights.count).to_a #every element is an array with all info on a user
    data_hash = Hash[users_id_array.zip pursed_batch] #hash of 6 users, user_id=>array of arraies the contain likes, books, movies...
    #raise graph.get_connections("509006501", "likes").to_s   can't get data on some people...
    #rasie data_hash.to_s
    
    #todo: delete this or make use of it
    #save the new pages #duplication with insert self data and likes, ignore nost of the time
    if rand()<LikeMeConfig.page_insertion_chance
      save_batch_pages(data_hash)
    end
    
            
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
              #user_page_relationship_array << UserPageRelationship.new(:relationship_type => category_name,:user_id => user_id,:page_id => like["id"])
              user_page_relationship_array << [category_name,user_id,like["id"]]
            end
          end        
        end           
      end

      unless user_page_relationship_array.empty?
        ActiveRecord::Base.transaction do
          UserPageRelationship.import [:relationship_type,:user_id,:page_id], user_page_relationship_array, :validate => false
          User.where(:id => users_id_array).update_all(:last_foregin_fb_update => Time.now) 
        end
        

      #user_page_relationship_string = "INSERT INTO user_page_relationships (relationship_type,user_id,page_id) VALUES "
      #user_page_relationship_array.each { |like|  user_page_relationship_string += "(\'#{like[0]}\',#{like[1]},#{like[2]}),"}
      #user_page_relationship_string[-1] = ';'
      #ActiveRecord::Base.connection.execute(user_page_relationship_string)
      end
      #UserPageRelationship.import user_page_relationship_array
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




  def insert_friend_to_db(fb_friend) #only for inserting self
    db_friend = User.find_or_initialize_by_id(fb_friend["id"])
    if db_friend.relationship_status == fb_friend["relationship_status"] #&& (fb_friend["relationship_status"] != nil) for people who can only update themselves   
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
    else
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
       :bio => fb_friend["bio"],
       :last_relationship_status_update => Time.now
    })
    end

    #raise fb_friend.to_s unless fb_friend["name"]=="Alon Rozental"
    return db_friend      
  end
  
  def insert_self_data_and_likes(my_graph)
    fb_me = my_graph.get_object("me")
    db_me = insert_friend_to_db(fb_me)
    
    my_id = db_me.id
    user_page_relationship_string = "INSERT INTO user_page_relationships (relationship_type,user_id,page_id) VALUES "
    page_id_array = []
        
    batch_results = my_graph.batch do |batch_api|#todo finish
      @@all_page_types.each do |category|
        batch_api.get_connections(my_id, category, :limit => 999)          
      end
    end

    page_array = []
    category_counter = 0
    @@all_page_types.each do |category|
      my_likes = batch_results[category_counter]
      category_char = get_char(category)      
      my_likes.each do |like|
        user_page_relationship_string += "(\'#{category_char}\',#{my_id},#{like["id"]}),"                
        #page_array << [like["category"],like["name"],like["id"]] unless category_char != 'l'     
      end
      category_counter = category_counter+1
    end
    
    unless user_page_relationship_string == "INSERT INTO user_page_relationships (relationship_type,user_id,page_id) VALUES "
      user_page_relationship_string[-1] = ';'
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("DELETE FROM user_page_relationships WHERE user_id = #{my_id}")
        ActiveRecord::Base.connection.execute(user_page_relationship_string)
      end
    end
    
    my_events = my_graph.get_connections("me", "events")
    my_events_id_array = my_events.collect { |event| event["id"]}
    ActiveRecord::Base.connection.disconnect!
    pid = Process.fork do
      ActiveRecord::Base.establish_connection
      self.insert_events(my_events_id_array,my_graph)
    end    
    Process.detach(pid)  
    ActiveRecord::Base.establish_connection
=begin
    attendance_array = []
    new_events_array = [] #event to insert to db
    my_events.each do |event|
      attendance_array<<[my_id,event["id"],event["rsvp_status"][0]]
      new_events_array<<[event["id"],event["name"],event["location"],event["start_time"],event["end_time"]]    
    end
    unless attendance_array.empty?
      ActiveRecord::Base.transaction do
        Attendance.where(:user_id => my_id).delete_all
        Attendance.import [:user_id,:event_id,:rsvp_status], attendance_array, :validate => false
      end
      ActiveRecord::Base.transaction do
        updated_events = new_events_array.collect{ |event| event[0]}
        Event.where(:id => updated_events).delete_all
        Event.import [:id,:name,:location,:start_time,:end_time], new_events_array, :validate => false
      end
    end
=end    
    
#pages    
=begin     
    #duplication with insert batches
    page_array.uniq!
    page_id_array = []
    page_array.each {|page| page_id_array << page[2].to_i}        
    existing_pages_id = Page.where(:id => page_id_array).pluck(:id)
    page_id_array = (page_id_array-existing_pages_id)
    page_array.select! { |page|  page_id_array.include?(page[2].to_i)}
    unless page_array.empty?
      page_string = "INSERT INTO pages (category,name,id) VALUES "
      page_array.each { |page|  page_string += "(\'#{page[0]}\',\'#{page[1].gsub("'", "''")}\',#{page[2]}),"}
      page_string[-1] = ';'
      ActiveRecord::Base.connection.execute(page_string)
    end
=end
    

  end
  
  def insert_events(events_id_array,graph)
    grouped_id_array = events_id_array.each_slice(50).to_a
    grouped_id_array.each do |partial_event_id_array|
      self.insert_50_events(partial_event_id_array,graph)
    end
  end
  
  def insert_50_events(events_id_array,graph) # up to 50 events
    
    #attending
    batch_attending = graph.batch do |batch_api|#array of arraies of hashes
      events_id_array.each do |id|
        batch_api.get_object(id.to_s + "/attending", :limit => 300)
      end   
    end
    attending_hash = Hash[events_id_array.zip batch_attending]
    attendance_array = []    
    attending_hash.each do |event_id,attending_list|
      attending_list.each do |attending|
        attendance_array<<[attending["id"],event_id,"a"]
      end      
    end
    
    #maybe
    batch_maybe = graph.batch do |batch_api|#array of arraies of hashes
      events_id_array.each do |id|
        batch_api.get_object(id.to_s + "/maybe", :limit => 50)
      end   
    end
    maybe_hash = Hash[events_id_array.zip batch_maybe]
    maybe_array = []    
    maybe_hash.each do |event_id,maybe_list|
      maybe_list.each do |maybe|
        maybe_array<<[maybe["id"],event_id,"m"]
      end      
    end
    
    #events
    batch_events = graph.batch do |batch_api|#array of arraies of hashes
      events_id_array.each do |id|
        batch_api.get_object(id.to_s)
      end   
    end
    events_array = []    
    batch_events.each do |event|
      events_array<<[event["id"],event["name"],event["location"],event["start_time"],event["end_time"],event["description"]]    
    end
    
    ActiveRecord::Base.transaction do
      Attendance.where(:event_id => events_id_array).delete_all unless events_id_array.empty?        
      Attendance.import [:user_id,:event_id,:rsvp_status], attendance_array, :validate => false unless attendance_array.empty?
      Attendance.import [:user_id,:event_id,:rsvp_status], maybe_array, :validate => false unless maybe_array.empty?
    end      
    ActiveRecord::Base.transaction do
      Event.where(:id => events_id_array).delete_all unless events_id_array.empty?   
      Event.import [:id,:name,:location,:start_time,:end_time,:description], events_array, :validate => false unless events_array.empty? 
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
      begin
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
      rescue
      end        
    end

    unless friends_array.blank? 
    existing_friends_id = User.where(:id => my_friends_id_array).pluck(:id)
    existing_friends_array = friends_array.select { |friend|  existing_friends_id.include?(friend["id"])}    
    new_friends_array = friends_array.reject { |friend|  existing_friends_id.include?(friend["id"])}
    
    
    now = Time.now
    friends_with_new_status = []
    old_friends_statuses = User.select("id, relationship_status").where(:id => my_friends_id_array).all
    
    fb_friend_hash = Hash[friends_array.map {|friend| [friend.id,friend.relationship_status]}]
    db_friend_hash = Hash[old_friends_statuses.map {|friend| [friend.id,friend.relationship_status]}]
    fb_friend_hash.each do |id,status|
      friends_with_new_status << id unless status == db_friend_hash[id] #todo || (status == nil) for people who can only update themselves 
    end
    #raise friends_with_new_status.to_s
    
      ActiveRecord::Base.transaction do
        unless existing_friends_array.blank? #todo: add relationship_status_update, batch or lose string
          existing_friends_array.each do |friend|
            update_string = "UPDATE users SET name='#{friend.name.gsub("'", "''")}'"
            update_string += ",location='#{friend.location.to_s.gsub("'", "''")}'" unless friend.location.blank?
            update_string += ",birthday='#{friend.birthday}'" unless friend.birthday.blank?
            update_string += ",hometown='#{friend.hometown.to_s.gsub("'", "''")}'" unless friend.hometown.blank?
            update_string += ",quotes='#{friend.quotes.gsub("'", "''")}'" unless friend.quotes.blank?
            update_string += ",relationship_status='#{friend.relationship_status.gsub("'", "''")}'" unless friend.relationship_status.blank?
            update_string += ",relationship_status=NULL" if (friend.relationship_status.blank? && (friends_with_new_status.include?(friend.id)))
            update_string += ",significant_other='#{friend.significant_other.to_s.gsub("'", "''")}'" unless friend.significant_other.blank?
            update_string += ",gender='#{friend.gender}'" unless friend.gender.blank?
            update_string += ",age=#{friend.age}" unless friend.age.blank?
            update_string += ",bio='#{friend.bio.gsub("'", "''")}'" unless friend.bio.blank?
            update_string += ",last_relationship_status_update='#{now}'" if (friends_with_new_status.include?(friend.id) && !(friend.birthday.blank? && friend.location.blank? && friend.hometown.blank? && friend.relationship_status.blank?))                                                  
            update_string += " WHERE id=#{friend.id}"
            ActiveRecord::Base.connection.execute(update_string)
          end
        end
        unless new_friends_array.blank?        
          User.import new_friends_array unless new_friends_array.blank?
        end
      end
    end 
     
    #frienships
    my_id = self.id.to_s 
    my_friends_id_array = []
        my_friends_id.each do |fb_friend|
      my_friends_id_array.push("(" + my_id + "," + fb_friend["id"] + ")")
    end
    my_friends_id_string=my_friends_id_array.to_s.gsub!("\"", "")
    #do it better with db constraints and no deletion? one transaction?
    #ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("DELETE FROM friendships WHERE user_id = #{my_id}")
      ActiveRecord::Base.connection.execute("INSERT INTO friendships (user_id, friend_id) VALUES #{my_friends_id_string[1..-2]}")
    #end
    #raise "bla2"
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
         
    #raise sliced_users_id.to_a.to_s
    #result is an array of a [user_id, score, chosen_likes]
    #ActiveRecord::Base.connection.disconnect!
    #results = Parallel.map(sliced_users_id, :in_threads=>LikeMeConfig.matching_cores) do |user_group| #processes lose db connection after function returns
    results = sliced_users_id.collect do |user_group| #in single process
      #ActiveRecord::Base.connection.reconnect!
      temp_filter = filter
      temp_filter.chosen_users = user_group
      users_query = temp_filter.get_users_query      
      users_pages = ActiveRecord::Base.connection.execute(users_query)
      #raise user_group.to_s
      #raise users_pages.to_a.to_s #of only 1 user
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
    #raise results.count.to_s
    return results
  end
  
     
  def find_matches(filter) #returns an array of [user,[chosen_likes],adjusted_score]
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
      outcome << [users[array[0]].first,array[2],adjust_score(array[1],filter.search_by)]
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
  
  def adjust_score(score,search_by)
    return 0 if score <= 0
    if search_by=="likes"
      score = Math.sqrt(score)
      score = score*2.5
      score = 1 if score > 1
      score = (score*100).to_i 
    else
      score = Math.sqrt(score)
      score = score*2
      score = 1 if score > 1
      score = (score*100).to_i      
    end

  end
  
############################################################### pages
  def find_pages(page_filter)
    #pages_select_users
    
    users_and_scores = self.pages_set_users_and_scores(page_filter) #Hash user_id => user_score
    page_filter.chosen_users = users_and_scores.keys
    #raise users_and_scores.to_s
    recommendations = page_filter.get_user_page_relationships
    page_scores = Hash.new
    
    recommendations.each do |recommendation|
      if page_scores[recommendation["page_id"]] #not first recommendation
        page_scores[recommendation["page_id"]] = [page_scores[recommendation["page_id"]][0] + users_and_scores[recommendation["user_id"].to_i],page_scores[recommendation["page_id"]][1].push(recommendation["user_id"])]
      else
        page_scores[recommendation["page_id"]] = [users_and_scores[recommendation["user_id"].to_i],[recommendation["user_id"]]]
        #raise page_scores[recommendation["page_id"]]
      end
    end
    if page_filter.relevant_pages == "exclude pages I know"
      my_likes_id = UserPageRelationship.where(:user_id => self.id, :relationship_type => 'l').pluck(:page_id)
      #raise page_scores.to_s
      page_scores.reject! { |score| my_likes_id.include?(score.to_i) }

    end
    #raise page_scores.to_s
    page_scores = page_scores.sort_by {|key, value| -1 *value[0]}
    #raise page_scores.to_s
    #raise recommendations.to_a.to_s
    return page_scores.first(100)
    
    
    #get users likes
    
    #Hash page_id => page_score
    #for_each like Hash[page_id] += 1*user_score
  end
  
  def pages_set_users_and_scores(page_filter)
    recommenders = LikeMeConfig.page_recommenders
    users_and_scores = Hash.new
    
    users_and_scores_category = Score.select("friend_id, score").where(:user_id => self.id, :category => get_char(page_filter.search_for)).order("score").reverse_order
    if page_filter.recommended_by == "friends"
      my_friends_id = self.friends.pluck(:id)
      users_and_scores_category = users_and_scores_category.where(:friend_id => my_friends_id)
    end
    users_and_scores_category = users_and_scores_category.first(recommenders)
    users_and_scores_category.reject! { |score| score.score < 0 }
    chosen_users = users_and_scores_category.collect{ |score| score.friend_id}    
    users_and_scores_category.each {|score| users_and_scores[score.friend_id]=score.score}
    #add more users from score table (likes) if less than number needed
    if users_and_scores_category.count < LikeMeConfig.page_recommenders
      users_and_scores_likes = Score.select("friend_id, score").where(:user_id => self.id, :category => "l").order("score").reverse_order
      if page_filter.recommended_by == "friends"
        #my_friends_id = self.friends.pluck(:id)
        users_and_scores_likes = users_and_scores_likes.where(:friend_id => my_friends_id)
      end
      users_and_scores_likes = users_and_scores_likes.first(recommenders)
      users_and_scores_likes.reject! { |score| score.score < 0 || chosen_users.include?(score.friend_id)}
      like_chosen_users = users_and_scores_likes.collect{ |score| score.friend_id}
      chosen_users = [chosen_users,like_chosen_users].flatten
      users_and_scores_likes.each {|score| users_and_scores[score.friend_id]=score.score}
    end

    if chosen_users.count < LikeMeConfig.page_recommenders
      filter = Filter.new
      filter.search_by = page_filter.search_for
      filter.social_network = "include only friends" if page_filter.recommended_by == "friends"
      scores_array = self.get_scores_array(filter)
      scores_array scores_array.first(LikeMeConfig.page_recommenders)
      scores_array.each do |array|
        users_and_scores[array[0]] = array[1]
      end
    end

    #raise users_and_scores.to_s
    return users_and_scores
  end
  
############################################################### events
  def find_events(event_filter,users_filter)
    #get 100? relevent events according to filter
    some_events_id_array = event_filter.get_events(self)
    
    
    #this "single process" way uses all CPUs for some reason but only to only 80%, maybe each does that
    #events_score_array = []
    #some_events_id_array.each { |event_id| events_score_array << calculate_event_score(event_id,users_filter) }    
    ActiveRecord::Base.connection.reconnect!
    events_score_array = Parallel.map(some_events_id_array, :in_processes=> 3) do |event_id|
      ActiveRecord::Base.connection.reconnect!
      a = calculate_event_score(event_id,users_filter) 
      ActiveRecord::Base.connection.reconnect!
      a
    end
    ActiveRecord::Base.connection.reconnect!
    
    events_score_array = events_score_array.sort_by {|array| array[1]*(-1)}
    events_score_array.first(50) #todo: some parameter
    
    #replace the id with the full event
    events_ids = []
    events_score_array.each { |event| events_ids << event[0]}
    events = Event.where(:id => events_ids).all
    events_hash = {}
    events.each {|event| events_hash[event.id]=event}
    full_events_score_array = []
    events_score_array.each { |event| full_events_score_array << [events_hash[event[0]],event[1],event[2]]}
    return full_events_score_array


    
    

  end
  
  def calculate_event_score(event_id,users_filter) #todo: add users filter to this function
    
    users_id = Attendance.where(:event_id => event_id).pluck(:user_id) #all in the event
    users_id = User.where(:id => users_id).pluck(:id) #all in event and db
    #users_filter.all_users_id_array = users_id.shuffle.first(LikeMeConfig.max_users_per_event)
    users_filter.all_users_id_array = users_id.first(LikeMeConfig.max_users_per_event) #no shuffle for time
    
    #raise find_matches(filter).to_s
    event_users_array = find_matches(users_filter)
    event_score = get_event_score_from_users_array(event_users_array)
    return [event_id,event_score,event_users_array]
  end
  
  def get_event_score_from_users_array(users_array) # array of [user,6 likes, adjusted user score]
    score = 0
    i=0.0
    n=5
    users_array = users_array.first(n)
    users_array.each do |user_likes_score| 
      score += user_likes_score[2]*(1-i/n)
      i+=1
    end
    return score
  end
  
     
end
