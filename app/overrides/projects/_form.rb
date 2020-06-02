Deface::Override.new :virtual_path  => "projects/_form",
                     :name          => "add-select-2-to-project-form",
                     :insert_after  => "erb[loud]:contains('call_hook(:view_projects_form')",
                     :text          => <<SELECT2

<script>
  $(function() {
    if ((typeof $().select2) === 'function') {
      $('.organization_cf').select2({
        containerCss: {minWidth: '300px'}
      });
    }
  });
</script>

SELECT2
