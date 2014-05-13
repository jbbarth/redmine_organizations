Deface::Override.new :virtual_path  => "users/show",
                     :name          => "add-organization-informations-to-users-profile",
                     :insert_before => "erb[silent]:contains('@memberships.empty?')",
                     :partial       => "users/organization_informations"
