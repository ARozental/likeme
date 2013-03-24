module ApplicationHelper
  def picture_link(id,size)
    size = "#{size}" #resolution is 120px
    id = "#{id}"
    html = "<a href=\"http://www.facebook.com/" + id + "\"><img src=\"https://graph.facebook.com/" + id + "/picture?width=120&height=120\" width=" + size + " height=" + size + "></a>"
    html.html_safe
  end
  
end
