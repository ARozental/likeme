# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#add_row(matches)

#jQuery ->
#  $(window).scroll ->
#    if $(window).scrollTop() > $(document).height() - $(window).height() - 20
#      matches = $('#matche_table').data('matches')
#      add_row(matches)

jQuery ->
  $('#main_div').scroll ->
    #ignore the condition because of different zoom levels
    #if $(window).scrollTop() > $(document).height() - $(window).height() - 60
    if ($('#matche_table').length > 0) 
      matches = $('#matche_table').data('matches')
      add_row(matches)
    else if ($('#page_table').length > 0) 
      pages = $('#page_table').data('pages')      
      add_page_row(pages)  

    
#jQuery ->
#  $('#main_div').scroll ->
#    alert("a")
#    pages = $('#page_table').data('pages')      
#    add_page_row(pages)      
#jQuery ->
#  $('#post_to_facebook').click ->
#    postToFeed()
