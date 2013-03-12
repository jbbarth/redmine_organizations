Deface::Override.new :virtual_path  => "users/show",
                     :name          => "add-organization-informations-to-users-profile",
                     :insert_before => "code[erb-silent]:contains('@memberships.empty?')",
                     :partial       => "users/organization_informations"
