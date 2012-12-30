/* Organizations plugin javascripts */
function toggleOrgaForms(id) {
  var orga_id = "#orga-"+id
  var $texts = $(orga_id+"-roles,"+orga_id+"-members")
  //=> doesn't work with forms, don't know why ... :/
  $texts.toggle(0, function(){
    var $forms = $(orga_id+"-roles-form,"+orga_id+"-members-form")
    if ($texts.is(":visible")) { $forms.hide() }
    else { $forms.show() }
  })
}

//filter organizations on organizations/index page
//TODO: merge it with the one in redmine_better_crossprojects plugin
$(function(){
  //focus on search field on load
  $("#filter-by-name").focus()
  //filter projects depending on input value
  $("#filter-by-name").on("keyup", function() {
    var needle = $.trim($(this).val().toLowerCase())
    var count = 0
    $(this).closest("table").find("td.name").each(function() {
      var name = $(this).data('filterValue').toLowerCase()
      var $elem = $(this).closest('tr')
      if (name.indexOf(needle) >= 0) {
        $elem.show()
        //restablish even/odd alternance
        $elem.removeClass("even")
        $elem.removeClass("odd")
        $elem.addClass(["odd", "even"][count % 2])
        count++
      } else {
        $elem.hide()
      }
    })
  })
})
