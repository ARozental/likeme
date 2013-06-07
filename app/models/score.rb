class Score < ActiveRecord::Base
  attr_accessible :user_id, :friend_id, :category, :score
end
