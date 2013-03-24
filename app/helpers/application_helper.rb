module ApplicationHelper
  def picture_link(id,size)
    size = "#{size}"
    id = "#{id}"
    html = "<a href=\"http://www.facebook.com/" + id + "\"><img src=\"https://graph.facebook.com/" + id + "/picture?width=200&height=200\" width=" + size + " height=" + size + "></a>"
    html.html_safe
  end
  
end
