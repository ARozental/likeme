module ApplicationHelper
  def picture_link(id,size)
    size = "#{size}" #resolution is 120px
    id = "#{id}"
    html = "<a href=\"http://www.facebook.com/" + id + "\"><img src=\"https://graph.facebook.com/" + id + "/picture?width=120&height=120\" width=" + size + " height=" + size + "></a>"
    html.html_safe
  end
  
  def name_link(user)
    html = "<a href=\"http://www.facebook.com/#{user.id}\">" + "#{user.name}" + "</a>"
    #html = "<a href=\"http://www.facebook.com/" + user.id + "\">" + user.name + "</a>"
    html.html_safe    
  end
  
  def print_stats(user)
    relationship_status=gender=age=location=""
    relationship_status = ", #{user.relationship_status}" unless user.relationship_status == nil 
    gender = ", #{user.gender}" unless user.gender == nil 
    age = ", #{user.age}" unless user.age == nil 
    location = ", #{user.location["name"]}" unless user.location == nil 
    
    html = relationship_status + gender + age + location
    html.html_safe
  end
  
end
