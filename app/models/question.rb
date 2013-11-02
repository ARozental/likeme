class Question < ActiveRecord::Base
  attr_accessible :allow_referrals, :anonymous, :bounty, :category, :choices, :for_people_like, :user_id
  attr_accessible :friends_limit, :gender_limit, :is_multiple_choice, :offensive_counter, :spam_counter, :text
  validates :text, length: { 
                            minimum: 5,
                            maximum: 1000
                            }
  validate :has_2_answers
  GENDER_OPTIONS = ['any','males','females']
  #GENDER_OPTIONS = [['Only males', 'male'], ['Only females', 'female'], ['people of any sex', nil]]
  validates_inclusion_of :gender_limit, :in => GENDER_OPTIONS
  
  serialize :choices
  belongs_to :user
  has_many :answers
  
  
  def has_2_answers
    begin
      if (self.is_multiple_choice && self.choices.split(',').size<2)
        errors.add(:choices, "needs at least 2 options")
        return false
      end
    rescue
    errors.add(:choices, "needs at least 2 options")
    return false
    end
    return true
  end
  

  
end
