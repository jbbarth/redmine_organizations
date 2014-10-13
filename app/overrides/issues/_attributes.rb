Deface::Override.new :virtual_path  => 'issues/_attributes',
                     :name          => 'add-assigned-organization-to-issues',
                     :replace       => "erb[loud]:contains(':assigned_to_id')",
                     :partial       => 'issues/add_assigned_organization_to_form'
