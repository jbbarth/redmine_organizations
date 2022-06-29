require_dependency "role"

class Role < ActiveRecord::Base
  has_many :organization_roles, :dependent => :destroy
end
