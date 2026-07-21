Deface::Override.new :virtual_path => 'issues/show',
                     :name         => 'show-organizations-in-issue-description',
                     :insert_after => '.attributes',
                     :partial      => 'issues/show_organizations'
