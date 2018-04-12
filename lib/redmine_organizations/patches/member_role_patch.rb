require_dependency 'member_role'

module PluginOrganization
  module MemberRole
    # NO nil member
    def add_role_to_group_users
      super unless self.member.nil?
    end
  end
end
MemberRole.prepend PluginOrganization::MemberRole
