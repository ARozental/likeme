OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, '360161967331340', 'd6900a8fcba7fc5ccfba40acff7a3967',
  :iframe => true,
  #:auth_type => 'https',
  #:secure_image_url => true,
  scope: %W( email user_about_me  user_activities  user_birthday  user_groups  user_hometown  user_interests  user_likes 
             user_location  user_relationships  user_relationship_details  user_religion_politics user_events
             friends_about_me  friends_activities  friends_birthday  friends_groups  friends_hometown  
             friends_interests  friends_likes  friends_location  friends_relationships  friends_relationship_details  
             friends_religion_politics friends_events).join(',')
  #alontest1 todo delete duplication 
  #provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_SECRET']
end
