Deface::Override.new  :virtual_path     => "projects/copy",
                        :name           => "copy-projects-activities",
                        :insert_after   => ".block:contains('@source_project.wiki.nil?')",
                        :text           => <<EOS
    <label class="block"><%= check_box_tag 'only[]', 'organizations_roles', true, :id => nil %> <%= l(:label_organizations_roles) %> (<%= @source_project.organization_roles.nil? ? 0 : @source_project.organization_roles.count %>)</label>
EOS