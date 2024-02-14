require_dependency 'member_role'

module RedmineOrganizations::Patches
  module MemberRolePatch
    # NO nil member
    def add_role_to_group_users
      super unless self.member.nil?
    end
  end
end
MemberRole.prepend RedmineOrganizations::Patches::MemberRolePatch
