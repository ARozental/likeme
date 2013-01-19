OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, '360161967331340', 'd6900a8fcba7fc5ccfba40acff7a3967' #alontest1 todo delete duplication 
  #provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_SECRET']
end
