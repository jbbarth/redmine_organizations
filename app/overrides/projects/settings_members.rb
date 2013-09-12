Deface::Override.new :virtual_path  => 'projects/settings/_members',
                     :name          => 'sort-members-by-group',
                     :insert_before => 'div.splitcontentleft',
                     :text          => '<%
  sorted_members = []
  #first groups
  members.select{|m| m.principal.is_a?(Group) }.each do |group_member|
    #the group itself
    sorted_members << group_member
    #its users present in members
    sorted_members += members.select{|m| m.principal.in?(group_member.principal.users)}
  end
  #users not in groups
  sorted_members += (members - sorted_members)
  #finally replace original "members" variable
  members = sorted_members
%>'

Deface::Override.new :virtual_path  => 'projects/settings/_members',
                     :name          => 'indent-members-inherited-from-groups',
                     :insert_before => 'code[erb-loud]:contains("link_to_user")',
                     :text          => '<%=
  content_tag(:span, "", :style => "display:inline-block;width:25px") if member.principal.is_a?(User) && !member.deletable?
%>'
