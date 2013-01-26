module ApplicationHelper
  def picture_link(id,size)
    size = "#{size}"
    html = "<a href=\"http://www.facebook.com/" + id + "\"><img src=\"https://graph.facebook.com/" + id + "/picture?type=normal\" width=" + size + " height=" + size + "></a>"
    html.html_safe
  end
  
end
