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
      matches = $('#matche_table').data('matches')
      add_row(matches)