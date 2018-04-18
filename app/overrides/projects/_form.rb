Deface::Override.new :virtual_path  => "projects/_form",
                     :name          => "add-notify_organizations-to-project",
                     :insert_before => "erb[silent]:contains('@project.custom_field_values.each do')",
                     :text          => "<p><%= f.check_box :notify_organizations %></p>"
