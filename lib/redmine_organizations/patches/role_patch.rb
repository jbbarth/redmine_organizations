require_dependency "role"

class Role < ActiveRecord::Base
  has_many :organization_roles, :dependent => :destroy
  has_many :organization_non_member_roles, :dependent => :destroy
end
