Deface::Override.new :virtual_path => 'roles/_form',
                     :name         => 'add-hide-role-checkbox',
                     :insert_after => 'p:contains(":issues_visibility")',
                     :text         => '<p><%= f.check_box :hidden_on_overview %></p>'
