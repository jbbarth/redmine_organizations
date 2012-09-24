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
