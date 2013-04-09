# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#add_row(matches)
jQuery ->
  $(window).scroll ->
    if $(window).scrollTop() > $(document).height() - $(window).height() - 20
      matches = $('#matche_table').data('matches')
      add_row(matches)
