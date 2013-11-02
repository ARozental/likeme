class Answer < ActiveRecord::Base
  attr_accessible :anonymous, :comment, :question_id, :ranked_by_user, :text, :user_id
end

#belongs_to :user
#belongs_to :question