require_dependency 'member_role'

class MemberRole
  def add_role_to_group_users_with_not_nil_member
    add_role_to_group_users_without_not_nil_member unless self.member.nil?
  end
  alias_method_chain :add_role_to_group_users, :not_nil_member
end
