Deface::Override.new :virtual_path => 'issues/_form',
                     :name         => 'add-organizations-to-issue-form',
                     :insert_after => '.attributes',
                     :partial      => 'issues/select_organizations'

Deface::Override.new :virtual_path => 'issues/_form_with_positions',
                     :name         => 'add-organizations-to-issue-form',
                     :insert_after => '.attributes',
                     :partial      => 'issues/select_organizations'
