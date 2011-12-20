/* Organizations plugin javascripts */
function toggleOrgaForms(id) {
  orga_id = 'orga-'+id;
  $(orga_id+'-roles',orga_id+'-roles-form',orga_id+'-members',orga_id+'-members-form').invoke('toggle');
}
